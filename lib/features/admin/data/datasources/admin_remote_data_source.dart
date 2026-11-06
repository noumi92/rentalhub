import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/admin_session.dart';

/// Phase A (A1–A4) — the admin panel's data layer.
///
/// Cloud Functions (enroll/verify/reset TOTP, setAdminRole) are called
/// through `cloud_functions`; team invites and the team list read
/// Firestore with an in-memory fallback for offline use and tests, the
/// same pattern the dispute data source uses. Firebase access resolves
/// lazily (try/catch → null), never in the constructor — an eager
/// resolution breaks widget tests with "Error while creating X".
class AdminInvite {
  const AdminInvite({
    required this.id,
    required this.email,
    required this.adminRole,
    this.expiresAt,
    required this.accepted,
    this.createdAt,
  });

  final String id;
  final String email;
  final String adminRole;
  final DateTime? expiresAt;
  final bool accepted;
  final DateTime? createdAt;

  bool get isExpired =>
      !accepted && expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory AdminInvite.fromMap(String id, Map<String, dynamic> data) {
    final expires = data['expires_at'];
    DateTime? expiresAt;
    if (expires is Timestamp) {
      expiresAt = expires.toDate();
    } else if (expires is String) {
      expiresAt = DateTime.tryParse(expires);
    }
    final created = data['created_at'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    return AdminInvite(
      id: id,
      email: data['email'] as String? ?? '',
      adminRole: data['admin_role'] as String? ?? '',
      expiresAt: expiresAt,
      accepted: data['accepted'] as bool? ?? false,
      createdAt: createdAt,
    );
  }
}

class AdminTeamMember {
  const AdminTeamMember({
    required this.uid,
    required this.email,
    required this.adminRole,
    required this.totpEnabled,
  });

  final String uid;
  final String email;
  final String adminRole;
  final bool totpEnabled;
}

/// One row of the immutable `audit_logs` collection (Phase A, A5).
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.type,
    required this.action,
    required this.actorEmail,
    required this.targetType,
    required this.targetId,
    required this.detail,
    this.decision,
    this.createdAt,
  });

  final String id;
  final String type;
  final String action;
  final String actorEmail;
  final String targetType;
  final String targetId;
  final String detail;
  final String? decision;
  final DateTime? createdAt;

  factory AuditLogEntry.fromMap(String id, Map<String, dynamic> data) {
    final created = data['created_at'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    return AuditLogEntry(
      id: id,
      type: data['type'] as String? ?? 'admin_action',
      action: data['action'] as String? ?? '',
      actorEmail: data['actor_email'] as String? ?? '',
      targetType: data['target_type'] as String? ?? '',
      targetId: data['target_id'] as String? ?? '',
      detail: data['detail'] as String? ?? '',
      decision: data['decision'] as String?,
      createdAt: createdAt,
    );
  }
}

class AdminProfile {
  const AdminProfile({
    required this.uid,
    this.email,
    this.adminRole,
    required this.totpEnabled,
  });

  final String uid;
  final String? email;
  final String? adminRole;
  final bool totpEnabled;
}

class AdminRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;
  final Map<String, Map<String, dynamic>> _inMemoryInvites = {};

  AdminRemoteDataSource({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore,
        _functions = functions;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFunctions? get _resolvedFunctions {
    if (_functions != null) return _functions;
    try {
      return FirebaseFunctions.instance;
    } catch (_) {
      return null;
    }
  }

  String? get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// The signed-in admin's role + TOTP state, from their users doc.
  /// Null when there is no signed-in user or the doc cannot be read.
  Future<AdminProfile?> getAdminProfile(String uid) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return null;
      return AdminProfile(
        uid: uid,
        email: data['email'] as String?,
        adminRole: data['admin_role'] as String?,
        totpEnabled: data['totp_enabled'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Start TOTP enrolment. Returns the otpauth:// URL to show as a QR
  /// code — it is returned ONCE, so the admin scans it now.
  Future<String> enrollTotp() async {
    final functions = _resolvedFunctions;
    if (functions == null) {
      throw Exception('Admin functions are unavailable right now.');
    }
    final result = await functions.httpsCallable('enrollTotp').call();
    final url = (result.data as Map?)?['otpauthUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('The server did not return a setup code.');
    }
    return url;
  }

  /// Verify a 6-digit TOTP code. Returns true when enrolment completed
  /// (first verify). Marks this session TOTP-verified on success.
  Future<bool> verifyTotp(String code) async {
    final functions = _resolvedFunctions;
    if (functions == null) {
      throw Exception('Admin functions are unavailable right now.');
    }
    final result =
        await functions.httpsCallable('verifyTotp').call({'code': code});
    final enrolled = (result.data as Map?)?['enrolled'] as bool? ?? false;
    final uid = _currentUid;
    if (uid != null) AdminSession.markTotpVerified(uid);
    return enrolled;
  }

  /// Reset TOTP for another admin (super admin only, enforced server-side).
  Future<void> resetTotp(String uid) async {
    final functions = _resolvedFunctions;
    if (functions == null) {
      throw Exception('Admin functions are unavailable right now.');
    }
    await functions.httpsCallable('resetTotp').call({'uid': uid});
  }

  /// Grant (adminRole set) or revoke (adminRole null) an admin role.
  /// A grant requires a valid, unexpired invite — enforced server-side.
  Future<String> setAdminRole({
    String? email,
    String? uid,
    String? adminRole,
  }) async {
    final functions = _resolvedFunctions;
    if (functions == null) {
      throw Exception('Admin functions are unavailable right now.');
    }
    final result = await functions.httpsCallable('setAdminRole').call({
      if (email != null) 'email': email,
      if (uid != null) 'uid': uid,
      'adminRole': adminRole,
    });
    return (result.data as Map?)?['message'] as String? ?? 'Done.';
  }

  /// Invite an admin (48 h expiry). The grant itself happens through
  /// setAdminRole once the invitee accepts — this only records the invite.
  Future<AdminInvite> createInvite({
    required String email,
    required String adminRole,
  }) async {
    final id = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final expiresAt = DateTime.now().add(const Duration(hours: 48));
    final record = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'admin_role': adminRole,
      'accepted': false,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    _inMemoryInvites[id] = record;
    final firestore = _resolvedFirestore;
    if (firestore != null) {
      try {
        await firestore.collection('admin_invites').add({
          ...record,
          'expires_at': Timestamp.fromDate(expiresAt),
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
    return AdminInvite.fromMap(id, record);
  }

  Future<List<AdminInvite>> getInvites() async {
    final firestore = _resolvedFirestore;
    if (firestore != null) {
      try {
        final snap =
            await firestore.collection('admin_invites').get();
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => AdminInvite.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => (b.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
          return list;
        }
      } catch (_) {}
    }
    final list = _inMemoryInvites.entries
        .map((e) => AdminInvite.fromMap(e.key, e.value))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  /// Withdraw an invite before it is accepted.
  Future<void> revokeInvite(String id) async {
    _inMemoryInvites.remove(id);
    final firestore = _resolvedFirestore;
    if (firestore != null) {
      try {
        await firestore.collection('admin_invites').doc(id).delete();
      } catch (_) {}
    }
  }

  /// Every user with an admin_role, newest enrolment first. Empty when
  /// Firestore cannot be reached — the team view says so honestly.
  Future<List<AdminTeamMember>> getTeamMembers() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('users')
          .where('admin_role', whereIn: ['super_admin', 'operations', 'support'])
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return AdminTeamMember(
          uid: d.id,
          email: data['email'] as String? ?? '',
          adminRole: data['admin_role'] as String? ?? '',
          totpEnabled: data['totp_enabled'] as bool? ?? false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// The activity log, newest first. The collection is immutable in
  /// rules — this only reads. Empty when Firestore cannot be reached.
  Future<List<AuditLogEntry>> getAuditLogs({int limit = 200}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('audit_logs')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => AuditLogEntry.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String auditLogsCsv(List<AuditLogEntry> entries) {
    final rows = <List<String>>[
      ['Date', 'Action', 'Actor', 'Target type', 'Target', 'Detail', 'Decision'],
      for (final e in entries)
        [
          e.createdAt?.toIso8601String() ?? '',
          e.action,
          e.actorEmail,
          e.targetType,
          e.targetId,
          e.detail.replaceAll(',', ';').replaceAll('\n', ' '),
          e.decision ?? '',
        ],
    ];
    return rows.map((r) => r.join(',')).join('\n');
  }

  /// Phase A (A6) — the dashboard KPIs, counted live from the
  /// collections. Zeros when Firestore cannot be reached — the dashboard
  /// says the counts are unavailable rather than inventing them.
  Future<PlatformStats> getPlatformStats() async {
    const empty = PlatformStats(
      shopCount: 0,
      activeBookingCount: 0,
      openDisputeCount: 0,
      openTicketCount: 0,
    );
    final firestore = _resolvedFirestore;
    if (firestore == null) return empty;
    try {
      final shops = await firestore.collection('shops').count().get();
      final bookings = await firestore
          .collection('bookings')
          .where('status', whereIn: [
            'approved',
            'payment_submitted',
            'paid',
            'active',
          ])
          .count()
          .get();
      final disputes = await firestore
          .collection('disputes')
          .where('status', isEqualTo: 'open')
          .count()
          .get();
      final tickets = await firestore
          .collection('support_tickets')
          .where('status', isEqualTo: 'open')
          .count()
          .get();
      return PlatformStats(
        shopCount: shops.count ?? 0,
        activeBookingCount: bookings.count ?? 0,
        openDisputeCount: disputes.count ?? 0,
        openTicketCount: tickets.count ?? 0,
      );
    } catch (_) {
      return empty;
    }
  }
}

/// The admin dashboard's KPI counts (Phase A, A6).
class PlatformStats {
  const PlatformStats({
    required this.shopCount,
    required this.activeBookingCount,
    required this.openDisputeCount,
    required this.openTicketCount,
  });

  final int shopCount;
  final int activeBookingCount;
  final int openDisputeCount;
  final int openTicketCount;
}
