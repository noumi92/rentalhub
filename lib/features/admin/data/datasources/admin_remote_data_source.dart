import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/utils/csv_escape.dart';
import '../../domain/admin_permissions.dart';
import '../services/admin_session.dart';
import 'admin_pagination.dart';

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
  ///
  /// F-C1: the client refuses the call too ([AdminPermission.
  /// manageTeam]) — the Function is the server-side backstop.
  /// Throws [StateError] when the caller may not manage the team.
  Future<void> resetTotp(String uid, {String? callerRole}) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.manageTeam,
        adminRole: callerRole)) {
      throw StateError('Only a super admin can manage the admin team.');
    }
    final functions = _resolvedFunctions;
    if (functions == null) {
      throw Exception('Admin functions are unavailable right now.');
    }
    await functions.httpsCallable('resetTotp').call({'uid': uid});
  }

  /// Grant (adminRole set) or revoke (adminRole null) an admin role.
  /// A grant requires a valid, unexpired invite — enforced server-side.
  ///
  /// F-C1: super admin only ([AdminPermission.manageTeam]) — the
  /// Function is the server-side backstop. Throws [StateError]
  /// when the caller may not manage the team.
  Future<String> setAdminRole({
    String? email,
    String? uid,
    String? adminRole,
    String? callerRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.manageTeam,
        adminRole: callerRole)) {
      throw StateError('Only a super admin can manage the admin team.');
    }
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
  ///
  /// F-C1: super admin only ([AdminPermission.manageTeam]).
  /// Throws [StateError] when the caller may not manage the team.
  ///
  /// Admin audit (2026-11-14, F-M5 / F-m17): a failed Firestore write
  /// used to be swallowed and the in-memory copy returned as if the
  /// invite existed — the UI then claimed "Invite sent" and logged
  /// `admin_invite_created` for an invite that lived only in that
  /// browser tab's memory. This throws on failure now, so the UI
  /// reports it honestly and nothing is logged for an invite that
  /// was never persisted (F-m11). The returned id is the Firestore
  /// document id from `add()`, so revoke deletes the real document
  /// instead of silently no-op-ing on a local `INV-<millis>` id.
  /// No email is sent here — there is no invite-mail Function yet
  /// (see the team view: the invite is saved and the accept link is
  /// shared manually until invite emails land with the Functions
  /// deploy). Never claim an email was sent.
  Future<AdminInvite> createInvite({
    required String email,
    required String adminRole,
    String? callerRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.manageTeam,
        adminRole: callerRole)) {
      throw StateError('Only a super admin can manage the admin team.');
    }
    final expiresAt = DateTime.now().add(const Duration(hours: 48));
    final record = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'admin_role': adminRole,
      'accepted': false,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      // No Firestore (unit tests / Firebase not initialised): keep
      // the in-memory record so the flow stays testable. The id is
      // local-only — the real path below always uses the document id.
      final id = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      _inMemoryInvites[id] = record;
      return AdminInvite.fromMap(id, record);
    }
    final docRef = await firestore.collection('admin_invites').add({
      ...record,
      'expires_at': Timestamp.fromDate(expiresAt),
      'created_at': FieldValue.serverTimestamp(),
    });
    return AdminInvite.fromMap(docRef.id, record);
  }

  /// Pending invites, newest first. Throws when Firestore is
  /// available but the read fails, so the team view shows its error
  /// state instead of "No pending invites" during an outage (F-M6).
  /// With no Firestore, returns the in-memory invites (tests).
  Future<List<AdminInvite>> getInvites() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      final list = _inMemoryInvites.entries
          .map((e) => AdminInvite.fromMap(e.key, e.value))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
      return list;
    }
    final snap = await firestore.collection('admin_invites').get();
    final list = snap.docs
        .map((d) => AdminInvite.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  /// Withdraw an invite before it is accepted.
  ///
  /// F-C1: super admin only ([AdminPermission.manageTeam]).
  /// Throws [StateError] when the caller may not manage the team.
  /// Throws on a failed delete (F-m5) — the caller reports the
  /// failure instead of letting a failed withdrawal silently
  /// reappear on reload.
  Future<void> revokeInvite(String id, {String? callerRole}) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.manageTeam,
        adminRole: callerRole)) {
      throw StateError('Only a super admin can manage the admin team.');
    }
    _inMemoryInvites.remove(id);
    final firestore = _resolvedFirestore;
    if (firestore == null) return;
    await firestore.collection('admin_invites').doc(id).delete();
  }

  /// Mark an invite accepted after the role was granted through
  /// setAdminRole, so it leaves the pending list and cannot be
  /// reused. Super admin only, like the other invite writes.
  /// Throws on a failed write — the accept view reports it instead
  /// of showing a grant that the invite list contradicts.
  Future<void> markInviteAccepted(String id, {String? callerRole}) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.manageTeam,
        adminRole: callerRole)) {
      throw StateError('Only a super admin can manage the admin team.');
    }
    final record = _inMemoryInvites[id];
    if (record != null) record['accepted'] = true;
    final firestore = _resolvedFirestore;
    if (firestore == null) return;
    await firestore.collection('admin_invites').doc(id).update({
      'accepted': true,
    });
  }

  /// Delete expired, unaccepted invites so they stop lingering in
  /// the list (F-m4). Returns how many were removed. Best-effort
  /// per document — one failed delete does not block the rest.
  /// No-op with no Firestore.
  Future<int> pruneExpiredInvites() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return 0;
    final snap = await firestore
        .collection('admin_invites')
        .where('accepted', isEqualTo: false)
        .where('expires_at', isLessThan: Timestamp.now())
        .get();
    var removed = 0;
    for (final doc in snap.docs) {
      try {
        await doc.reference.delete();
        removed++;
      } catch (_) {}
    }
    return removed;
  }

  /// Record that a super admin asked this admin to turn on 2FA
  /// (F-m4 — the "2FA-off reminder"). The reminded admin sees it at
  /// their next sign-in (admin login view). Throws on failure so the
  /// team view reports it instead of claiming a reminder was sent.
  /// Super admin only, like the other team-management writes.
  Future<void> recordTotpReminder(String uid, {String? callerRole}) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.manageTeam,
        adminRole: callerRole)) {
      throw StateError('Only a super admin can manage the admin team.');
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      throw Exception('Admin functions are unavailable right now.');
    }
    await firestore.collection('admin_totp_reminders').doc(uid).set({
      'reminded_at': FieldValue.serverTimestamp(),
      'reminded_by': _currentUid,
    }, SetOptions(merge: true));
  }

  /// Whether a 2FA-off reminder is waiting for this admin. False
  /// when there is none, or when the read itself fails — a failed
  /// read must never block sign-in.
  Future<bool> hasTotpReminder(String uid) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      final doc = await firestore
          .collection('admin_totp_reminders')
          .doc(uid)
          .get();
      return doc.data() != null;
    } catch (_) {
      return false;
    }
  }

  /// Every user with an admin_role, newest enrolment first.
  ///
  /// Admin audit (2026-11-14, F-M6): a failed read used to return
  /// `[]`, so an outage rendered as "No admins found". It throws
  /// now — the team view shows its error state with a retry. `[]`
  /// is returned only with no Firestore (tests).
  Future<List<AdminTeamMember>> getTeamMembers() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
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
  }

  /// The activity log, newest first. The collection is immutable in
  /// rules — this only reads. Empty when Firestore cannot be reached.
  Future<List<AuditLogEntry>> getAuditLogs({int limit = 200}) async {
    final page = await getAuditLogsPage(limit: limit);
    return page.items;
  }

  /// One page of the activity log, newest first — the old silent
  /// 200-row cap is now explicit pagination: the view loads further
  /// pages with the returned cursor.
  ///
  /// F-M6: a failed read throws (the view shows its error state)
  /// instead of returning an empty page that reads as "no entries".
  Future<AdminPage<AuditLogEntry>> getAuditLogsPage({
    int limit = 50,
    Object? cursor,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return const AdminPage(items: [], hasMore: false);
    }
    var query = firestore
        .collection('audit_logs')
        .orderBy('created_at', descending: true)
        .limit(limit + 1);
    final lastDoc = cursor is DocumentSnapshot ? cursor : null;
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    final docs = snap.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    return AdminPage(
      items: pageDocs
          .map((d) => AuditLogEntry.fromMap(d.id, d.data()))
          .toList(),
      hasMore: hasMore,
      cursor: hasMore ? pageDocs.last : null,
    );
  }

  /// Server-side activity-log filters (F-m3): action type, actor
  /// email, and a date range. The query carries no `orderBy` on
  /// purpose — an equality filter plus an order on another field
  /// needs a composite index, and `firestore.indexes.json` holds
  /// none — so the matches are sorted newest-first in memory and
  /// capped at 200, with [countAuditLogsFiltered] reporting how many
  /// matched in total.
  ///
  /// The action filter is a family prefix (`support_ticket`
  /// matches `support_ticket_closed`, `support_ticket_replied`,
  /// …), because several actions carry a dynamic suffix no
  /// exact-match dropdown could list.
  ///
  /// F-M6: a failed read throws instead of returning `[]`.
  Future<List<AuditLogEntry>> getAuditLogsFiltered({
    String? actionPrefix,
    String? actorEmail,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    Query<Map<String, dynamic>> query =
        firestore.collection('audit_logs');
    if (actionPrefix != null && actionPrefix.isNotEmpty) {
      query = query
          .where('action', isGreaterThanOrEqualTo: actionPrefix)
          .where('action', isLessThanOrEqualTo: '$actionPrefix\uf8ff');
    }
    if (actorEmail != null && actorEmail.isNotEmpty) {
      query = query.where('actor_email', isEqualTo: actorEmail);
    }
    if (from != null) {
      query = query.where('created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('created_at',
          isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final snap = await query.limit(limit).get();
    final list = snap.docs
        .map((d) => AuditLogEntry.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  /// How many entries the current filter matches in total, so the
  /// view can say "N matching entries" instead of silently capping.
  /// F-M6: a failed read throws instead of returning 0.
  Future<int> countAuditLogsFiltered({
    String? actionPrefix,
    String? actorEmail,
    DateTime? from,
    DateTime? to,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return 0;
    Query<Map<String, dynamic>> query =
        firestore.collection('audit_logs');
    if (actionPrefix != null && actionPrefix.isNotEmpty) {
      query = query
          .where('action', isGreaterThanOrEqualTo: actionPrefix)
          .where('action', isLessThanOrEqualTo: '$actionPrefix\uf8ff');
    }
    if (actorEmail != null && actorEmail.isNotEmpty) {
      query = query.where('actor_email', isEqualTo: actorEmail);
    }
    if (from != null) {
      query = query.where('created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('created_at',
          isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    final count = await query.count().get();
    return count.count ?? 0;
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
          e.detail,
          e.decision ?? '',
        ],
    ];
    // F-m10: RFC 4180 escaping — the old version replaced commas
    // with ';' and newlines with spaces, silently rewriting the
    // audit text; a detail containing a quote could still misalign
    // a row. The text is now exported verbatim, quoted when needed.
    return rows.map(csvRow).join('\n');
  }

  /// Phase A (A6) — the dashboard KPIs, counted live from the
  /// collections.
  ///
  /// F-M6: a failed count throws — the dashboard shows its error
  /// state instead of zeros labelled "Live count". Zeros are
  /// returned only with no Firestore (tests / Firebase not
  /// initialised), i.e. "loaded, zero" is a real loaded state and
  /// "failed to load" is an error state.
  Future<PlatformStats> getPlatformStats() async {
    const empty = PlatformStats(
      shopCount: 0,
      activeBookingCount: 0,
      openDisputeCount: 0,
      openTicketCount: 0,
      pendingShopCount: 0,
    );
    final firestore = _resolvedFirestore;
    if (firestore == null) return empty;
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
    // F-m1: the approvals queue is the most actionable queue on
    // the platform — the dashboard counts it alongside the rest.
    final pendingShops = await firestore
        .collection('shops')
        .where('verification_status', isEqualTo: 'pending')
        .count()
        .get();
    return PlatformStats(
      shopCount: shops.count ?? 0,
      activeBookingCount: bookings.count ?? 0,
      openDisputeCount: disputes.count ?? 0,
      openTicketCount: tickets.count ?? 0,
      pendingShopCount: pendingShops.count ?? 0,
    );
  }
}

/// The admin dashboard's KPI counts (Phase A, A6).
class PlatformStats {
  const PlatformStats({
    required this.shopCount,
    required this.activeBookingCount,
    required this.openDisputeCount,
    required this.openTicketCount,
    required this.pendingShopCount,
  });

  final int shopCount;
  final int activeBookingCount;
  final int openDisputeCount;
  final int openTicketCount;

  /// Shops with `verification_status == 'pending'` — the approvals
  /// queue (F-m1). Counted live like the other KPIs.
  final int pendingShopCount;
}
