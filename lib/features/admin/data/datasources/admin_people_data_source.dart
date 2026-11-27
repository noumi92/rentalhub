import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../blacklist/domain/entities/blacklist_entity.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/data/models/customer_model.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../trust/data/models/customer_qr_code_model.dart';
import '../../../trust/data/services/trust_score_service.dart';
import '../../domain/admin_permissions.dart';
import '../../domain/trust_score_calculator.dart';
import '../services/admin_audit_service.dart';
import 'admin_pagination.dart';
import '../services/admin_session.dart';

/// Phase C — the people side of the admin panel: customers, the
/// platform blacklist, and the trust score.
///
/// The trust score shown here is the C3 formula, computed live by the
/// shared [TrustScoreService] (the same service the customer app
/// reads) — it is computed, not stored. The `trust_score` field on
/// the users doc is the older stored value; Phase 4 (4.4b) keeps it
/// out of the UI entirely (it used to show as a list hint and a
/// detail comparison, and disagreed with the live score).
/// for comparison, not as the source of truth.
class AdminPeopleDataSource {
  final FirebaseFirestore? _firestore;

  AdminPeopleDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<List<CustomerModel>> getCustomers() async {
    final page = await getCustomersPage(limit: 200);
    return page.items.map((r) => r.customer).toList();
  }

  /// One page of the customers list, with the row data the list
  /// itself needs (F-m8): the flags (and the stored trust score,
  /// still read for the data layer but no longer displayed — the
  /// customer detail computes the live score, which is
  /// authoritative). Flags come
  /// from the documents that own them (`is_blacklisted` on the
  /// users doc, `watchlisted` on the customers doc).
  ///
  /// Pagination replaces the old silent 200-row cap. `cnicFilter`
  /// is 'all' | 'onFile' | 'missing' (CNIC on the customers doc);
  /// the CNIC filter is applied while paging, scanning at most
  /// 1000 customers to fill a page.
  ///
  /// F-M6: a failed read throws — the customers view shows its error
  /// state instead of "No customers match" during an outage. An
  /// empty page is returned only with no Firestore (tests).
  /// Phase 4 (4.3) — client-side sort over loaded customer rows
  /// (the no-Firestore path and the view's search results).
  static List<AdminCustomerRow> sortCustomerRows(
      List<AdminCustomerRow> rows, String sort) {
    final list = List<AdminCustomerRow>.of(rows);
    switch (sort) {
      case 'nameDesc':
        list.sort((a, b) =>
            b.customer.name.compareTo(a.customer.name));
      case 'dateNewest':
        list.sort((a, b) =>
            b.customer.createdAt.compareTo(a.customer.createdAt));
      case 'dateOldest':
        list.sort((a, b) =>
            a.customer.createdAt.compareTo(b.customer.createdAt));
      default:
        list.sort((a, b) =>
            a.customer.name.compareTo(b.customer.name));
    }
    return list;
  }

  /// Phase 4 (4.3) — client-side sort over loaded blacklist
  /// records (the tribunal is client-side). 'statusAsc' puts
  /// active cases first.
  static List<AdminBlacklistRecord> sortBlacklistRecords(
      List<AdminBlacklistRecord> records, String sort) {
    final list = List<AdminBlacklistRecord>.of(records);
    DateTime at(AdminBlacklistRecord r) =>
        r.entity.reportedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    switch (sort) {
      case 'dateOldest':
        list.sort((a, b) => at(a).compareTo(at(b)));
      case 'statusAsc':
        list.sort((a, b) {
          final c = (a.entity.isActive ? 0 : 1)
              .compareTo(b.entity.isActive ? 0 : 1);
          return c != 0 ? c : at(b).compareTo(at(a));
        });
      default:
        list.sort((a, b) => at(b).compareTo(at(a)));
    }
    return list;
  }

  /// Phase 4 (4.4c) — how many customers exist in total, so the
  /// list can say "Showing first N of M". The CNIC filter has no
  /// server-side count (CNIC presence is not a queryable field),
  /// so the view reports the total only for the unfiltered list.
  Future<int> countCustomers() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return (await getCustomers()).length;
    final count = await firestore.collection('customers').count().get();
    return count.count ?? 0;
  }

  Future<AdminPage<AdminCustomerRow>> getCustomersPage({
    int limit = 20,
    Object? cursor,
    String cnicFilter = 'all',
    String sort = 'nameAsc',
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return const AdminPage(items: [], hasMore: false);
    }
    final matched = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    DocumentSnapshot? lastDoc =
        cursor is DocumentSnapshot ? cursor : null;
    var scanned = 0;
    var exhausted = false;
    // Phase 4 (4.3) — the sort is server-side: name A–Z / Z–A
    // orders by `name`, date by `createdAt` (ISO strings, so
    // lexical order is chronological). The CNIC filter is still
    // applied while scanning, as before.
    while (matched.length < limit && scanned < 1000 && !exhausted) {
      var query = firestore.collection('customers').orderBy(
          sort == 'dateNewest' || sort == 'dateOldest'
              ? 'createdAt'
              : 'name',
          descending:
              sort == 'nameDesc' || sort == 'dateNewest').limit(50);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);
      final snap = await query.get();
      if (snap.docs.isEmpty) {
        exhausted = true;
        break;
      }
      scanned += snap.docs.length;
      lastDoc = snap.docs.last;
      for (final d in snap.docs) {
        final cnic = (d.data()['cnic'] as String?) ?? '';
        if (cnicFilter == 'onFile' && cnic.isEmpty) continue;
        if (cnicFilter == 'missing' && cnic.isNotEmpty) continue;
        matched.add(d);
        if (matched.length >= limit) break;
      }
      if (snap.docs.length < 50) exhausted = true;
    }
    final rows = await Future.wait(
      matched.map((d) => _rowFromDoc(firestore, d)),
    );
    return AdminPage(
      items: rows,
      // More pages exist when the scan stopped on a full batch
      // (or mid-batch with docs left) rather than running out.
      hasMore: !exhausted && scanned < 1000,
      cursor: !exhausted && scanned < 1000 ? lastDoc : null,
    );
  }

  /// Server-side customer search: it covers the whole list, not
  /// just the loaded page. Firestore has no substring search, so
  /// the search scans the list in bounded pages (at most 500
  /// customers) for a name/phone/CNIC match — the same
  /// case-insensitive "contains" the old client-side search used,
  /// now over the collection instead of the loaded page.
  Future<List<AdminCustomerRow>> searchCustomers(
    String query, {
    int limit = 50,
  }) async {
    final firestore = _resolvedFirestore;
    final needle = query.trim().toLowerCase();
    if (firestore == null || needle.isEmpty) return [];
    try {
      final matched = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      DocumentSnapshot? lastDoc;
      var scanned = 0;
      while (matched.length < limit && scanned < 500) {
        var pageQuery = firestore
            .collection('customers')
            .orderBy('name')
            .limit(100);
        if (lastDoc != null) {
          pageQuery = pageQuery.startAfterDocument(lastDoc);
        }
        final snap = await pageQuery.get();
        if (snap.docs.isEmpty) break;
        scanned += snap.docs.length;
        lastDoc = snap.docs.last;
        for (final d in snap.docs) {
          final data = d.data();
          final haystack =
              '${data['name'] ?? ''} ${data['phone'] ?? ''} ${data['cnic'] ?? ''}'
                  .toLowerCase();
          if (haystack.contains(needle)) {
            matched.add(d);
            if (matched.length >= limit) break;
          }
        }
        if (snap.docs.length < 100) break;
      }
      return await Future.wait(matched.map((d) => _rowFromDoc(firestore, d)));
    } catch (_) {
      return [];
    }
  }

  Future<AdminCustomerRow> _rowFromDoc(
    FirebaseFirestore firestore,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final customer = CustomerModel.fromMap(doc.data(), doc.id);
    double? storedTrustScore;
    var isBlacklisted = false;
    try {
      final userDoc =
          await firestore.collection('users').doc(doc.id).get();
      final userData = userDoc.data();
      storedTrustScore = (userData?['trust_score'] as num?)?.toDouble();
      isBlacklisted = userData?['is_blacklisted'] as bool? ?? false;
    } catch (_) {}
    return AdminCustomerRow(
      customer: customer,
      storedTrustScore: storedTrustScore,
      isBlacklisted: isBlacklisted,
      watchlisted: doc.data()['watchlisted'] as bool? ?? false,
    );
  }

  /// F-M6: throws on a failed read; null only when the customer
  /// doc is missing or the live trust score cannot be computed
  /// (the detail view shows "not found" for null, its error state
  /// for a throw).
  Future<CustomerDetail?> getCustomerDetail(String customerId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    final customerDoc =
        await firestore.collection('customers').doc(customerId).get();
    final customerData = customerDoc.data();
    if (customerData == null) return null;
    final customer = CustomerModel.fromMap(customerData, customerDoc.id);

    final userDoc =
        await firestore.collection('users').doc(customerId).get();
    final userData = userDoc.data();
    final storedTrustScore =
        (userData?['trust_score'] as num?)?.toDouble();
    final isBlacklisted = userData?['is_blacklisted'] as bool? ?? false;

    // The live score — one shared computation (TrustScoreService),
    // the same one the customer app reads.
    final trust = await TrustScoreService(firestore: firestore)
        .compute(customerId);
    if (trust == null) return null;
    final bookings = trust.bookings;
    final kycStatus = trust.kycStatus;
    final kycCnic = trust.kycCnic;
    final completedTrips = trust.completedTrips;
    final meanRating = trust.meanOwnerRating;
    final breakdown = trust.breakdown;

    BlacklistEntity? blacklistRecord;
    final cnic = customer.cnic ?? kycCnic;
    if (cnic != null && cnic.isNotEmpty) {
      blacklistRecord = await BlacklistRemoteDataSource(
              firestore: firestore)
          .getBlacklistRecordByCnic(cnic);
    }

    final notesSnap = await firestore
        .collection('customers')
        .doc(customerId)
        .collection('admin_notes')
        .orderBy('created_at', descending: true)
        .limit(20)
        .get();
    final notes = notesSnap.docs
        .map((d) => AdminNote.fromMap(d.id, d.data()))
        .toList();

    return CustomerDetail(
      customer: customer,
      storedTrustScore: storedTrustScore,
      isBlacklisted: isBlacklisted,
      // AD-M6: the watchlist flag lives on the customers doc, so
      // the detail screen can offer remove-from-watchlist.
      isWatchlisted: customerData['watchlisted'] as bool? ?? false,
      kycStatus: kycStatus,
      bookings: bookings,
      completedTrips: completedTrips,
      meanOwnerRating: meanRating,
      trustBreakdown: breakdown,
      blacklistRecord: blacklistRecord,
      notes: notes,
    );
  }

  /// The CNIC back-QR number for a customer, from the restricted
  /// `customer_qr_codes/{customerId}` doc. The caller must already
  /// have checked the role is super_admin — the Firestore rules deny
  /// the read for anyone else, and a denied or missing doc reads as
  /// null here, never an exception.
  Future<String?> getCustomerQrCode(String customerId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore
          .collection(CustomerQrCodeModel.collection)
          .doc(customerId)
          .get();
      final data = doc.data();
      if (data == null) return null;
      final code = CustomerQrCodeModel.fromMap(data, doc.id).qrCode;
      return code.isEmpty ? null : code;
    } catch (_) {
      return null;
    }
  }

  /// A watchlist flag on the customer record (admin eyes only).
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// manageBlacklist]). The caller's role is passed by the view
  /// when it already resolved it, otherwise resolved from the
  /// session here; an unresolvable role refuses the write.
  Future<bool> setCustomerWatchlisted({
    required String customerId,
    required bool watchlisted,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageBlacklist,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('customers').doc(customerId).update({
        'watchlisted': watchlisted,
      });
      await AdminAuditService.logAction(
        action: watchlisted
            ? 'customer_watchlisted'
            : 'customer_unwatchlisted',
        targetType: 'customer',
        targetId: customerId,
        detail: watchlisted
            ? 'Customer added to the watchlist.'
            : 'Customer removed from the watchlist.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Report a customer to the shared blacklist (C2). The report goes
  /// through the shared blacklist data source so the booking-time
  /// check sees it immediately.
  ///
  /// Phase 3 (3.6b): `reasonCategory` must be one of
  /// [BlacklistReasonCategory] — a free-text category is refused, so
  /// the tribunal's categories stay reportable instead of drifting
  /// into one-off strings. The free-text detail lives in
  /// `description` alone.
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// manageBlacklist]) — see [setCustomerWatchlisted].
  Future<bool> reportCustomerToBlacklist({
    required String customerId,
    required String cnic,
    required String phone,
    required String reasonCategory,
    required String description,
    required String reportedByShopId,
    String? adminRole,
  }) async {
    if (BlacklistReasonCategory.fromValue(reasonCategory) == null) {
      return false;
    }
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageBlacklist,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await BlacklistRemoteDataSource(firestore: firestore)
          .reportCustomerToBlacklist(
        cnicNumber: cnic,
        phoneNumber: phone,
        reasonCategory: reasonCategory,
        description: description,
        reportedByShopId: reportedByShopId,
      );
      await AdminAuditService.logAction(
        action: 'customer_blacklisted',
        targetType: 'customer',
        targetId: customerId,
        detail: '$reasonCategory: $description',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// F-C1: an admin note is an admin-only write — super admin +
  /// operations ([AdminPermission.manageBlacklist], the people-side
  /// permission) — see [setCustomerWatchlisted].
  ///
  /// Phase 3 (3.5b): the note carries its author (the signed-in
  /// admin's uid and email, when a session exists) and the write
  /// leaves an audit entry, so the activity log can answer who
  /// wrote what, and when.
  Future<bool> addCustomerNote({
    required String customerId,
    required String text,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageBlacklist,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      String? authorId;
      String? authorEmail;
      try {
        final user = FirebaseAuth.instance.currentUser;
        authorId = user?.uid;
        authorEmail = user?.email;
      } catch (_) {}
      await firestore
          .collection('customers')
          .doc(customerId)
          .collection('admin_notes')
          .add({
        'text': text,
        if (authorId != null) 'author_id': authorId,
        if (authorEmail != null) 'author_email': authorEmail,
        'created_at': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action: 'customer_note_added',
        targetType: 'customer',
        targetId: customerId,
        detail: text,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Phase 3 (3.6a) — the tribunal-to-customer link: the blacklist
  /// record carries a CNIC, not a customer id, so resolve the
  /// customer whose `customers` doc carries that CNIC. Null when
  /// no customer record matches (or with no Firestore).
  Future<String?> getCustomerIdByCnic(String cnic) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final snap = await firestore
          .collection('customers')
          .where('cnic', isEqualTo: cnic)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  /// Every blacklist record, active and reverted, newest first.
  ///
  /// F-M6: the list read is strict — a failed Firestore read throws
  /// (the tribunal shows its error state) instead of rendering an
  /// empty tribunal during an outage. With no Firestore, the
  /// session's reported records are returned. The per-record
  /// appeal-state read stays best-effort: a failed appeal read
  /// leaves that record's appeal as 'none' rather than failing
  /// the whole tribunal.
  Future<List<AdminBlacklistRecord>> getBlacklistRecords() async {
    final firestore = _resolvedFirestore;
    final records = await BlacklistRemoteDataSource(firestore: firestore)
        .getAllRecordsStrict();
    final out = <AdminBlacklistRecord>[];
    for (final r in records) {
      var appealStatus = 'none';
      var appealReason = '';
      if (firestore != null) {
        try {
          final doc = await firestore
              .collection('blacklist')
              .doc(r.blacklistId)
              .get();
          appealStatus =
              doc.data()?['appeal_status'] as String? ?? 'none';
          appealReason = doc.data()?['appeal_reason'] as String? ?? '';
        } catch (_) {}
      }
      out.add(AdminBlacklistRecord(
        entity: r,
        appealStatus: appealStatus,
        appealReason: appealReason,
      ));
    }
    return out;
  }

  /// Decide an appeal: 'keep' leaves the flag in place (appeal
  /// denied), 'remove' lifts it via the tribunal revert (reason
  /// mandatory, logged). Returns false when the write failed.
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// manageBlacklist]) — see [setCustomerWatchlisted].
  Future<bool> decideAppeal({
    required String blacklistId,
    required String decision,
    required String reason,
    required String adminUid,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageBlacklist,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      if (decision == 'remove') {
        await BlacklistRemoteDataSource(firestore: firestore)
            .revertBlacklistRecord(
          blacklistId: blacklistId,
          adminUid: adminUid,
          justification: reason,
        );
      }
      await firestore.collection('blacklist').doc(blacklistId).update({
        'appeal_status': decision == 'keep' ? 'kept' : 'removed',
        'appeal_reason': reason,
        'appeal_decided_at': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action: decision == 'keep'
            ? 'blacklist_appeal_kept'
            : 'blacklist_appeal_removed',
        targetType: 'blacklist',
        targetId: blacklistId,
        detail: reason,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// One row of the admin customers list (F-m8): the customer plus
/// the trust hint and flags the list shows. The stored trust score
/// is a hint only — the live score on the detail screen governs.
class AdminCustomerRow {
  const AdminCustomerRow({
    required this.customer,
    required this.storedTrustScore,
    required this.isBlacklisted,
    required this.watchlisted,
  });

  final CustomerModel customer;
  final double? storedTrustScore;
  final bool isBlacklisted;
  final bool watchlisted;
}

/// Everything the customer detail screen shows, assembled from the
/// collections that actually hold it.
class CustomerDetail {
  const CustomerDetail({
    required this.customer,
    required this.storedTrustScore,
    required this.isBlacklisted,
    this.isWatchlisted = false,
    required this.kycStatus,
    required this.bookings,
    required this.completedTrips,
    required this.meanOwnerRating,
    required this.trustBreakdown,
    required this.blacklistRecord,
    required this.notes,
  });

  final CustomerEntity customer;
  final double? storedTrustScore;
  final bool isBlacklisted;
  final bool isWatchlisted;
  final String kycStatus;
  final List<BookingEntity> bookings;
  final int completedTrips;
  final double? meanOwnerRating;
  final TrustScoreBreakdown trustBreakdown;
  final BlacklistEntity? blacklistRecord;
  final List<AdminNote> notes;
}

/// An admin's private note on a customer.
///
/// Phase 3 (3.5b): the author is the signed-in admin who wrote it
/// (`author_id` / `author_email`); older notes have neither.
class AdminNote {
  const AdminNote({
    required this.id,
    required this.text,
    this.createdAt,
    this.authorId,
    this.authorEmail,
  });

  final String id;
  final String text;
  final DateTime? createdAt;
  final String? authorId;
  final String? authorEmail;

  factory AdminNote.fromMap(String id, Map<String, dynamic> data) {
    final created = data['created_at'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    return AdminNote(
      id: id,
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
      authorId: data['author_id'] as String?,
      authorEmail: data['author_email'] as String?,
    );
  }
}

/// Phase 3 (3.6b) — the real reason categories for a blacklist
/// report. The stored value is the kebab-case string ([value]);
/// anything outside this set is refused by
/// [AdminPeopleDataSource.reportCustomerToBlacklist], so the
/// tribunal's categories stay reportable.
enum BlacklistReasonCategory {
  fraud('fraud'),
  lateReturn('late-return'),
  damage('damage'),
  nonPayment('non-payment'),
  abusiveBehaviour('abusive-behaviour'),
  other('other');

  const BlacklistReasonCategory(this.value);

  final String value;

  static BlacklistReasonCategory? fromValue(String value) {
    for (final c in BlacklistReasonCategory.values) {
      if (c.value == value) return c;
    }
    return null;
  }
}

/// A blacklist record with its appeal state (C2). The appeal fields
/// live on the blacklist document; the shared entity does not carry
/// them, so this admin-side wrapper holds them.
class AdminBlacklistRecord {
  const AdminBlacklistRecord({
    required this.entity,
    required this.appealStatus,
    required this.appealReason,
  });

  final BlacklistEntity entity;
  final String appealStatus;
  final String appealReason;
}
