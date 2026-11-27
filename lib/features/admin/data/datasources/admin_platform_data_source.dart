import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/money_format.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/domain/entities/security_deposit_entity.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../services/admin_audit_service.dart';
import '../services/admin_session.dart';
import 'admin_pagination.dart';

/// Phase D — the platform side of the admin panel: bookings, the
/// disputes centre, and reviews moderation.
///
/// D2 note: the dispute decision is stored on the dispute document
/// (`decision`, `decision_amount`, `admin_note`) and read back onto
/// `DisputeRecord`, so the admin centre and the customer's own
/// dispute record both show the outcome. The shop is notified
/// through an in-app notification record, and the customer gets one
/// too — a `notifications` record addressed by `customerId` (there
/// is still no customer notifications feed UI to display it, so the
/// decision on the dispute record itself is the channel the customer
/// can read today). WhatsApp stays gated on D2 — no WhatsApp send is
/// faked here. The C3 trust score already counts a decision against
/// the customer (deducted deposits + adverse dispute decisions), so a
/// confirmed-damage decision lowers the score automatically.
class AdminPlatformDataSource {
  final FirebaseFirestore? _firestore;

  AdminPlatformDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// F-M6: a failed read throws — the bookings view shows its error
  /// state instead of "No bookings match" during an outage. `[]`
  /// is returned only with no Firestore (tests).
  Future<List<BookingModel>> getBookings({String status = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    var query = firestore.collection('bookings').limit(200);
    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    final list = snap.docs
        .map((d) => BookingModel.fromMap(d.data(), d.id))
        .toList();
    list.sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
    return list;
  }

  /// Phase 4 (4.3) — client-side sort over a loaded list (the
  /// no-Firestore branch and the view's search results).
  static List<BookingModel> sortBookings(
      List<BookingModel> bookings, String sort) {
    final list = List<BookingModel>.of(bookings);
    switch (sort) {
      case 'dateOldest':
        list.sort((a, b) => a.pickupTime.compareTo(b.pickupTime));
      case 'amountHigh':
        list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      case 'amountLow':
        list.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
      case 'statusAsc':
        list.sort((a, b) {
          final c = a.status.compareTo(b.status);
          return c != 0
              ? c
              : b.pickupTime.compareTo(a.pickupTime);
        });
      default:
        list.sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
    }
    return list;
  }

  /// Phase 3 (3.4) — one page of bookings, newest pickup first. A
  /// status-filtered page is ordered by `pickupTime` on the server
  /// (`status` + `pickupTime` composite index in
  /// firestore.indexes.json), so filtered pages paginate with a
  /// cursor like the unfiltered inbox. With no Firestore the page
  /// is cut from [getBookings] in memory (integer-offset cursor),
  /// so offline fakes that override [getBookings] keep working.
  Future<AdminPage<BookingModel>> getBookingsPage({
    String status = 'all',
    int limit = 20,
    Object? cursor,
    String sort = 'dateNewest',
  }) async {
    final firestore = _resolvedFirestore;
    final total = await countBookings(status: status);
    if (firestore == null) {
      final all = sortBookings(await getBookings(status: status), sort);
      final offset = cursor is int ? cursor : 0;
      final page = all.skip(offset).take(limit).toList();
      return AdminPage(
        items: page,
        hasMore: offset + page.length < all.length,
        cursor: offset + page.length < all.length
            ? offset + page.length
            : null,
        total: all.length,
      );
    }
    // Phase 4 (4.3) — the sort is server-side. Date orders by
    // `pickupTime`, amount by `totalAmount`, status by `status`
    // then newest pickup; the status-filtered amount/date-oldest
    // orders need their composite indexes in
    // firestore.indexes.json (status+pickupTime ASC,
    // status+totalAmount ASC/DESC).
    Query<Map<String, dynamic>> base(String field, bool descending) {
      Query<Map<String, dynamic>> q = firestore.collection('bookings');
      if (status != 'all') {
        q = q.where('status', isEqualTo: status);
      }
      return q.orderBy(field, descending: descending);
    }

    var query = switch (sort) {
      'dateOldest' => base('pickupTime', false),
      'amountHigh' => base('totalAmount', true),
      'amountLow' => base('totalAmount', false),
      'statusAsc' =>
        base('status', false).orderBy('pickupTime', descending: true),
      _ => base('pickupTime', true),
    };
    var paged = query.limit(limit + 1);
    final lastDoc = cursor is DocumentSnapshot ? cursor : null;
    if (lastDoc != null) paged = paged.startAfterDocument(lastDoc);
    final snap = await paged.get();
    final docs = snap.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    return AdminPage(
      items: pageDocs
          .map((d) => BookingModel.fromMap(d.data(), d.id))
          .toList(),
      hasMore: hasMore,
      cursor: hasMore ? pageDocs.last : null,
      total: total,
    );
  }

  /// Phase 3 (3.4) — how many bookings the current filter matches
  /// in total, so the list can say "Showing first N of M".
  Future<int> countBookings({String status = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return (await getBookings(status: status)).length;
    }
    var query = firestore.collection('bookings');
    final count = await (status == 'all'
            ? query.count()
            : query.where('status', isEqualTo: status).count())
        .get();
    return count.count ?? 0;
  }

  /// Phase 3 (3.4) — server-side booking search: it covers the
  /// whole list, not just the loaded page. A booking-ID match is a
  /// direct document read; anything else scans the bookings in
  /// bounded pages (at most 500) for a customer / vehicle / shop
  /// match — the same case-insensitive "contains" the old
  /// client-side search used. With no Firestore it filters
  /// [getBookings] in memory.
  Future<List<BookingModel>> searchBookings(
    String query, {
    String status = 'all',
    int limit = 50,
  }) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return (await getBookings(status: status))
          .where((b) =>
              b.bookingId.toLowerCase().contains(needle) ||
              (b.customerName ?? '').toLowerCase().contains(needle) ||
              (b.vehicleName ?? '').toLowerCase().contains(needle) ||
              (b.shopName ?? '').toLowerCase().contains(needle))
          .take(limit)
          .toList();
    }
    try {
      final found = <BookingModel>[];
      final direct = await firestore
          .collection('bookings')
          .doc(query.trim())
          .get();
      final directData = direct.data();
      if (directData != null) {
        final booking = BookingModel.fromMap(directData, direct.id);
        if (status == 'all' || booking.status == status) {
          return [booking];
        }
      }
      DocumentSnapshot? lastDoc;
      var scanned = 0;
      while (found.length < limit && scanned < 500) {
        var pageQuery = firestore
            .collection('bookings')
            .orderBy('pickupTime', descending: true)
            .limit(100);
        if (lastDoc != null) {
          pageQuery = pageQuery.startAfterDocument(lastDoc);
        }
        final snap = await pageQuery.get();
        if (snap.docs.isEmpty) break;
        scanned += snap.docs.length;
        lastDoc = snap.docs.last;
        for (final d in snap.docs) {
          final booking = BookingModel.fromMap(d.data(), d.id);
          if (status != 'all' && booking.status != status) continue;
          if (booking.bookingId.toLowerCase().contains(needle) ||
              (booking.customerName ?? '')
                  .toLowerCase()
                  .contains(needle) ||
              (booking.vehicleName ?? '')
                  .toLowerCase()
                  .contains(needle) ||
              (booking.shopName ?? '').toLowerCase().contains(needle)) {
            found.add(booking);
            if (found.length >= limit) break;
          }
        }
        if (snap.docs.length < 100) break;
      }
      return found;
    } catch (_) {
      return [];
    }
  }

  /// F-M6: throws when the booking document itself cannot be read
  /// (the detail view shows its error state); null only when the
  /// booking does not exist. The optional sections (agreement,
  /// handover, dispute, return, messages) stay best-effort: a
  /// failed sub-read leaves that section empty rather than failing
  /// the whole detail.
  Future<BookingDetail?> getBookingDetail(String bookingId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    final bookingDoc =
        await firestore.collection('bookings').doc(bookingId).get();
    final bookingData = bookingDoc.data();
    if (bookingData == null) return null;
    final booking = BookingModel.fromMap(bookingData, bookingDoc.id);

    final deposit = await SecurityDepositDataSource(firestore: firestore)
        .getByBookingId(bookingId);

      String? agreementPdfUrl;
      try {
        final agreementDoc = await firestore
            .collection('agreements')
            .doc(bookingId)
            .get();
        agreementPdfUrl =
            agreementDoc.data()?['agreementPdfUrl'] as String?;
      } catch (_) {}

      HandoverSummary? handover;
      try {
        final handoverDoc = await firestore
            .collection('handovers')
            .doc(bookingId)
            .get();
        final handoverData = handoverDoc.data();
        if (handoverData != null) {
          handover = HandoverSummary.fromMap(handoverData);
        }
      } catch (_) {}

      DisputeRecord? dispute;
      try {
        final disputeSnap = await firestore
            .collection('disputes')
            .where('bookingId', isEqualTo: bookingId)
            .limit(1)
            .get();
        if (disputeSnap.docs.isNotEmpty) {
          dispute = _disputeFromDoc(
              disputeSnap.docs.first.id, disputeSnap.docs.first.data());
        }
      } catch (_) {}

      // F-M16: the return checklist lives on
      // `return_settlements/{bookingId}` (condition, photos, payment,
      // totals) — read it so the detail can show the return, not
      // just the pickup handover.
      ReturnSettlementSummary? returnSettlement;
      try {
        final returnDoc = await firestore
            .collection('return_settlements')
            .doc(bookingId)
            .get();
        final returnData = returnDoc.data();
        if (returnData != null) {
          returnSettlement = ReturnSettlementSummary.fromMap(returnData);
        }
      } catch (_) {}

      final messages = <AdminMessage>[];
      try {
        final messagesSnap = await firestore
            .collection('notifications')
            .where('bookingId', isEqualTo: bookingId)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
        for (final d in messagesSnap.docs) {
          messages.add(AdminMessage.fromMap(d.data()));
        }
      } catch (_) {}

      return BookingDetail(
        booking: booking,
        deposit: deposit,
        agreementPdfUrl: agreementPdfUrl,
        handover: handover,
        dispute: dispute,
        messages: messages,
        returnSettlement: returnSettlement,
      );
  }

  /// Phase 2 (2.4): one dispute for its detail route. F-M6: throws
  /// when the document cannot be read (the detail view shows its
  /// error state); null only when the dispute does not exist, or
  /// with no Firestore (tests).
  Future<DisputeRecord?> getDispute(String disputeId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    final doc =
        await firestore.collection('disputes').doc(disputeId).get();
    final data = doc.data();
    if (data == null) return null;
    return _disputeFromDoc(doc.id, data);
  }

  /// F-M6: a failed read throws (see [getBookings]).
  Future<List<DisputeRecord>> getDisputes({String status = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    var query = firestore.collection('disputes').limit(100);
    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    final list = snap.docs
        .map((d) => _disputeFromDoc(d.id, d.data()))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  /// Phase 4 (4.3) — client-side sort over a loaded list (the
  /// disputes centre is client-side: [getDisputes] caps at 100).
  static List<DisputeRecord> sortDisputes(
      List<DisputeRecord> disputes, String sort) {
    final list = List<DisputeRecord>.of(disputes);
    DateTime at(DisputeRecord d) =>
        d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    switch (sort) {
      case 'dateOldest':
        list.sort((a, b) => at(a).compareTo(at(b)));
      case 'statusAsc':
        list.sort((a, b) {
          final c = a.status.compareTo(b.status);
          return c != 0 ? c : at(b).compareTo(at(a));
        });
      default:
        list.sort((a, b) => at(b).compareTo(at(a)));
    }
    return list;
  }

  /// Phase 4 (4.3) — client-side sort over the loaded reviews
  /// (the moderation view is client-side: [getReviews] caps at
  /// 200). Rating uses the shop rating, falling back to the
  /// vehicle rating; a review with neither rates 0.
  static List<AdminReview> sortReviews(
      List<AdminReview> reviews, String sort) {
    final list = List<AdminReview>.of(reviews);
    double rating(AdminReview r) =>
        (r.shopRating ?? r.vehicleRating ?? 0).toDouble();
    switch (sort) {
      case 'ratingHigh':
        list.sort((a, b) => rating(b).compareTo(rating(a)));
      case 'ratingLow':
        list.sort((a, b) => rating(a).compareTo(rating(b)));
      case 'statusAsc':
        list.sort((a, b) => a.moderationStatus.compareTo(b.moderationStatus));
      default:
        break;
    }
    return list;
  }

  /// Phase 3 (3.4) — one page of disputes, newest first, with the
  /// same cursor pagination as the tickets inbox (status +
  /// `createdAt` composite index in firestore.indexes.json). With
  /// no Firestore the page is cut from [getDisputes] in memory.
  Future<AdminPage<DisputeRecord>> getDisputesPage({
    String status = 'all',
    int limit = 20,
    Object? cursor,
  }) async {
    final firestore = _resolvedFirestore;
    final total = await countDisputes(status: status);
    if (firestore == null) {
      final all = await getDisputes(status: status);
      final offset = cursor is int ? cursor : 0;
      final page = all.skip(offset).take(limit).toList();
      return AdminPage(
        items: page,
        hasMore: offset + page.length < all.length,
        cursor: offset + page.length < all.length
            ? offset + page.length
            : null,
        total: all.length,
      );
    }
    var query = firestore
        .collection('disputes')
        .orderBy('createdAt', descending: true);
    if (status != 'all') {
      query = firestore
          .collection('disputes')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true);
    }
    var paged = query.limit(limit + 1);
    final lastDoc = cursor is DocumentSnapshot ? cursor : null;
    if (lastDoc != null) paged = paged.startAfterDocument(lastDoc);
    final snap = await paged.get();
    final docs = snap.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    return AdminPage(
      items: pageDocs
          .map((d) => _disputeFromDoc(d.id, d.data()))
          .toList(),
      hasMore: hasMore,
      cursor: hasMore ? pageDocs.last : null,
      total: total,
    );
  }

  /// Phase 3 (3.4) — how many disputes the current filter matches
  /// in total, so the centre can say "Showing first N of M" at its
  /// 100 cap.
  Future<int> countDisputes({String status = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return (await getDisputes(status: status)).length;
    }
    final count = await (status == 'all'
            ? firestore.collection('disputes').count()
            : firestore
                .collection('disputes')
                .where('status', isEqualTo: status)
                .count())
        .get();
    return count.count ?? 0;
  }

  /// Phase 3 (3.4) — how many reviews exist in total, so the
  /// moderation view can say "Showing first N of M" at its 200 cap.
  Future<int> countReviews() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return (await getReviews()).length;
    final count = await firestore.collection('reviews').count().get();
    return count.count ?? 0;
  }

  /// Phase 3 (3.3a) — the most a dispute decision may award: the
  /// booking's outstanding balance plus the security deposit still
  /// held for it. Both figures come from the records themselves
  /// (`bookings/{id}.remainingBalance` and
  /// `security_deposits/{bookingId}.amount` while its status is
  /// `collected`, falling back to the booking's
  /// `depositAmountPkr` when no deposit record exists) — nothing
  /// here is invented, and a negative total is clamped to zero.
  static int disputeAmountCap({
    required int remainingBalance,
    required int depositHeld,
  }) =>
      (remainingBalance + depositHeld) < 0
          ? 0
          : remainingBalance + depositHeld;

  DisputeRecord _disputeFromDoc(
      String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    final resolved = data['resolved_at'];
    DateTime? resolvedAt;
    if (resolved is Timestamp) {
      resolvedAt = resolved.toDate();
    } else if (resolved is String) {
      resolvedAt = DateTime.tryParse(resolved);
    }
    return DisputeRecord(
      id: id,
      bookingId: data['bookingId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      createdAt: createdAt,
      shopId: data['shopId'] as String?,
      customerName: data['customerName'] as String?,
      customerId: data['customerId'] as String?,
      decision: data['decision'] as String?,
      decisionAmount: (data['decision_amount'] as num?)?.toInt(),
      adminNote: data['admin_note'] as String?,
      resolvedAt: resolvedAt,
    );
  }

  /// Decide a dispute (D2). Decision values: 'full_to_customer' |
  /// 'partial' | 'full_to_owner'. The 72 h SLA is measured from the
  /// dispute's createdAt; the view shows how long is left.
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// decideDispute]) — support may view and triage the queue but
  /// never decide. The caller's role is passed by the sheet when it
  /// already resolved it, otherwise resolved from the session here;
  /// an unresolvable role refuses the write (fail closed).
  Future<bool> decideDispute({
    required String disputeId,
    required String decision,
    required int decisionAmount,
    required String adminNote,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.decideDispute,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      final doc =
          await firestore.collection('disputes').doc(disputeId).get();
      final data = doc.data();
      if (data == null) return false;
      // Phase 3 (3.3b) — status precondition: a dispute that is
      // already decided cannot be re-decided. A resolved dispute
      // (or one carrying a decision) is read-only history.
      if (data['status'] == 'resolved' || data['decision'] != null) {
        return false;
      }
      if (decision != 'full_to_customer' &&
          decision != 'partial' &&
          decision != 'full_to_owner') {
        return false;
      }
      if (decisionAmount < 0) return false;
      // Phase 3 (3.3a) — the amount is capped at the outstanding
      // balance plus the deposit still held for the booking. The
      // booking must exist to verify the cap: when it cannot be
      // read the decision is refused rather than awarded against
      // money that may not be there.
      final disputeBookingId = data['bookingId'] as String?;
      if (disputeBookingId != null && disputeBookingId.isNotEmpty) {
        final bookingDoc = await firestore
            .collection('bookings')
            .doc(disputeBookingId)
            .get();
        final bookingData = bookingDoc.data();
        if (bookingData == null) return false;
        final remaining =
            (bookingData['remainingBalance'] as num?)?.toInt() ?? 0;
        final deposit = await SecurityDepositDataSource(
                firestore: firestore)
            .getByBookingId(disputeBookingId);
        final depositHeld = deposit != null
            ? (deposit.status == 'collected' ? deposit.amount : 0)
            : (bookingData['depositAmountPkr'] as num?)?.toInt() ?? 0;
        final cap = disputeAmountCap(
          remainingBalance: remaining,
          depositHeld: depositHeld,
        );
        if (decisionAmount > cap) return false;
      }
      await firestore.collection('disputes').doc(disputeId).update({
        'status': 'resolved',
        'decision': decision,
        'decision_amount': decisionAmount,
        'admin_note': adminNote,
        'resolved_at': FieldValue.serverTimestamp(),
      });
      final shopId = data['shopId'] as String?;
      final bookingId = data['bookingId'] as String?;
      final customerId = data['customerId'] as String?;
      if (shopId != null && shopId.isNotEmpty) {
        await NotificationDataSource(firestore: firestore)
            .createNotification(
          shopId: shopId,
          title: 'Dispute decided',
          body:
              'Dispute $disputeId was decided: $decision (Rs. ${formatRs(decisionAmount)}).',
          type: 'dispute_decided',
          bookingId: bookingId,
        );
      }
      // F-M10: the customer — the party who filed the dispute — gets
      // an in-app notification record too, addressed by customerId
      // so a customer notifications feed can read it. Best effort:
      // a failure here never fails the decision itself.
      if (customerId != null && customerId.isNotEmpty) {
        try {
          final id =
              'NTF-${DateTime.now().millisecondsSinceEpoch}';
          await firestore.collection('notifications').doc(id).set({
            'notificationId': id,
            'customerId': customerId,
            'title': 'Dispute decided',
            'body':
                'Your dispute $disputeId was decided: $decision (Rs. ${formatRs(decisionAmount)}).',
            'type': 'dispute_decided',
            if (bookingId != null) 'bookingId': bookingId,
            'createdAt': DateTime.now().toIso8601String(),
            'read': false,
          });
        } catch (_) {}
      }
      // F-M11: the booking leaves the `disputed` state. Restore the
      // status it had before the dispute was filed; when no previous
      // status was recorded (older disputes), leave it `disputed`
      // rather than inventing one.
      if (bookingId != null && bookingId.isNotEmpty) {
        try {
          final bookingRef =
              firestore.collection('bookings').doc(bookingId);
          final bookingDoc = await bookingRef.get();
          final bookingData = bookingDoc.data();
          final previous =
              bookingData?['statusBeforeDispute'] as String?;
          if (bookingData?['status'] == 'disputed' &&
              previous != null &&
              previous.isNotEmpty) {
            await bookingRef.update({
              'status': previous,
              'statusBeforeDispute': FieldValue.delete(),
            });
          }
        } catch (_) {}
      }
      await AdminAuditService.logAction(
        action: 'dispute_decided_$decision',
        targetType: 'dispute',
        targetId: disputeId,
        detail: 'Rs. ${formatRs(decisionAmount)} — $adminNote',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// F-m14: move a dispute from `open` to `in_review` — the triage
  /// step the centre's filter already offers but no admin action
  /// could perform. Returns false when the write fails.
  ///
  /// F-C1: triage, so every admin role holds it ([AdminPermission.
  /// manageDisputes]) — see [decideDispute] for the deciding side.
  Future<bool> markDisputeInReview({
    required String disputeId,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.manageDisputes,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('disputes').doc(disputeId).update({
        'status': 'in_review',
      });
      await AdminAuditService.logAction(
        action: 'dispute_marked_in_review',
        targetType: 'dispute',
        targetId: disputeId,
        detail: 'Dispute moved to in review.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// All review documents with their moderation state and the
  /// auto-check signals (D3). A review enters a queue when it has a
  /// signal; the admin's decision is what makes it hidden, not the
  /// signal itself.
  ///
  /// F-M6: a failed read throws (see [getBookings]).
  Future<List<AdminReview>> getReviews() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    final snap = await firestore
        .collection('reviews')
        .limit(200)
        .get();
    return snap.docs
        .map((d) => AdminReview.fromMap(d.id, d.data()))
        .toList();
  }

  /// Keep / Hide / Ask-to-edit / Warn (D3). Status values: 'visible' |
  /// 'hidden' | 'edit_requested' | 'warned'.
  ///
  /// F-C1: super admin + operations only. The matrix has no
  /// dedicated reviews permission, so moderation rides on
  /// [AdminPermission.managePlatform] (a platform-level decision)
  /// — see [decideDispute].
  Future<bool> setReviewModeration({
    required String reviewId,
    required String status,
    required String reason,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.managePlatform,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('reviews').doc(reviewId).update({
        'moderation_status': status,
        'moderation_reason': reason,
        'moderated_at': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action: 'review_moderation_$status',
        targetType: 'review',
        targetId: reviewId,
        detail: reason,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Everything the booking detail screen shows, assembled from the
/// collections that hold it. The timeline is derived from the
/// booking's own fields — there is no separate timeline collection.
class BookingDetail {
  const BookingDetail({
    required this.booking,
    required this.deposit,
    required this.agreementPdfUrl,
    required this.handover,
    required this.dispute,
    required this.messages,
    this.returnSettlement,
  });

  final BookingEntity booking;
  final SecurityDepositEntity? deposit;
  final String? agreementPdfUrl;
  final HandoverSummary? handover;
  final DisputeRecord? dispute;
  final List<AdminMessage> messages;

  /// The return checklist (`return_settlements/{bookingId}`), null
  /// when the vehicle has not been returned through the settlement
  /// flow yet.
  final ReturnSettlementSummary? returnSettlement;
}

/// The handover record for a booking (pickup checklist + odometer).
class HandoverSummary {
  const HandoverSummary({
    required this.initialOdometer,
    required this.fuelLevel,
    required this.damageNotes,
    required this.agreementPdfUrl,
    this.photoFrontUrl,
    this.photoBackUrl,
    this.photoLeftUrl,
    this.photoRightUrl,
    this.documentsGiven = const [],
    this.accessories = const [],
    this.keysHandedOver = false,
  });

  final int initialOdometer;
  final String fuelLevel;
  final List<String> damageNotes;
  final String? agreementPdfUrl;

  /// F-M16: the four exterior photos (cPanel signed URLs), the
  /// documents handed to the customer, the accessories in the car,
  /// and whether the keys were handed over — the evidence in a
  /// damage dispute. Null/empty when not taken or not recorded.
  final String? photoFrontUrl;
  final String? photoBackUrl;
  final String? photoLeftUrl;
  final String? photoRightUrl;
  final List<String> documentsGiven;
  final List<String> accessories;
  final bool keysHandedOver;

  factory HandoverSummary.fromMap(Map<String, dynamic> data) {
    return HandoverSummary(
      initialOdometer: (data['initialOdometer'] as num?)?.toInt() ?? 0,
      fuelLevel: data['fuelLevel'] as String? ?? '',
      damageNotes:
          List<String>.from(data['damageNotes'] as List? ?? const []),
      agreementPdfUrl: data['agreementPdfUrl'] as String?,
      photoFrontUrl: data['photoFrontUrl'] as String?,
      photoBackUrl: data['photoBackUrl'] as String?,
      photoLeftUrl: data['photoLeftUrl'] as String?,
      photoRightUrl: data['photoRightUrl'] as String?,
      documentsGiven:
          List<String>.from(data['documentsGiven'] as List? ?? const []),
      accessories:
          List<String>.from(data['accessories'] as List? ?? const []),
      keysHandedOver: data['keysHandedOver'] as bool? ?? false,
    );
  }
}

/// The return checklist for a booking, from
/// `return_settlements/{bookingId}` (see
/// `ReturnSettlementService.finalizeReturn`). The return odometer
/// itself is not stored here — it is the handover odometer plus the
/// deposit record's `totalKmDriven`.
class ReturnSettlementSummary {
  const ReturnSettlementSummary({
    required this.condition,
    required this.returnPhotoUrls,
    required this.paymentMethod,
    required this.remainingRentCollected,
    required this.remainingRentDue,
    required this.netRefund,
    required this.totalDeductions,
    this.completedAt,
  });

  final String condition;
  final Map<String, String> returnPhotoUrls;
  final String? paymentMethod;
  final int remainingRentCollected;
  final int remainingRentDue;
  final int netRefund;
  final int totalDeductions;
  final DateTime? completedAt;

  factory ReturnSettlementSummary.fromMap(Map<String, dynamic> data) {
    final photos = <String, String>{};
    final rawPhotos = data['returnPhotoUrls'];
    if (rawPhotos is Map) {
      for (final e in rawPhotos.entries) {
        if (e.value is String && (e.value as String).isNotEmpty) {
          photos[e.key.toString()] = e.value as String;
        }
      }
    }
    final completed = data['completedAt'];
    DateTime? completedAt;
    if (completed is Timestamp) {
      completedAt = completed.toDate();
    } else if (completed is String) {
      completedAt = DateTime.tryParse(completed);
    }
    return ReturnSettlementSummary(
      condition: data['condition'] as String? ?? '',
      returnPhotoUrls: photos,
      paymentMethod: data['paymentMethod'] as String?,
      remainingRentCollected:
          (data['remainingRentCollected'] as num?)?.toInt() ?? 0,
      remainingRentDue: (data['remainingRentDue'] as num?)?.toInt() ?? 0,
      netRefund: (data['netRefund'] as num?)?.toInt() ?? 0,
      totalDeductions: (data['totalDeductions'] as num?)?.toInt() ?? 0,
      completedAt: completedAt,
    );
  }
}

/// One notification record tied to a booking — the messages log on
/// the booking detail screen.
class AdminMessage {
  const AdminMessage({
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String title;
  final String body;
  final DateTime? createdAt;

  factory AdminMessage.fromMap(Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    return AdminMessage(
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}

/// One review document with its moderation state and the auto-check
/// signals that put it in a queue. The signals are heuristics —
/// a 1-star rating, abusive/fake keywords in a comment, or a
/// lopsided pair (customer 1-star while the owner rated 5, or the
/// reverse) — and never hide a review on their own.
class AdminReview {
  const AdminReview({
    required this.id,
    required this.bookingId,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.vehicleName,
    required this.shopRating,
    required this.vehicleRating,
    required this.customerComment,
    required this.ownerPunctuality,
    required this.ownerCare,
    required this.ownerBehavior,
    required this.ownerComment,
    required this.moderationStatus,
    required this.moderationReason,
    required this.signals,
  });

  final String id;
  final String bookingId;
  final String shopId;
  final String customerId;
  final String? customerName;
  final String? vehicleName;
  final int? shopRating;
  final int? vehicleRating;
  final String customerComment;
  final int? ownerPunctuality;
  final int? ownerCare;
  final int? ownerBehavior;
  final String ownerComment;
  final String moderationStatus;
  final String moderationReason;
  final List<String> signals;

  factory AdminReview.fromMap(String id, Map<String, dynamic> data) {
    final shopRating = (data['shopRating'] as num?)?.toInt();
    final vehicleRating = (data['vehicleRating'] as num?)?.toInt();
    final ownerPunctuality = (data['punctualityRating'] as num?)?.toInt();
    final ownerCare = (data['careRating'] as num?)?.toInt();
    final ownerBehavior = (data['behaviorRating'] as num?)?.toInt();
    final comment =
        '${data['customerComment'] as String? ?? ''} ${data['ownerComment'] as String? ?? ''}';
    final signals = <String>[];
    final customerComment = data['customerComment'] as String? ?? '';
    if ((shopRating == 1 || vehicleRating == 1) &&
        customerComment.trim().isEmpty) {
      signals.add('Fake review: 1-star with no comment');
    }
    final lower = comment.toLowerCase();
    const abusiveWords = [
      'fraud',
      'scam',
      'cheat',
      'thief',
      'stolen',
      'fake',
      'liar',
      'robbed',
    ];
    if (abusiveWords.any(lower.contains)) {
      signals.add('Abusive / fake wording');
    }
    final ownerMean = [ownerPunctuality, ownerCare, ownerBehavior]
        .whereType<int>()
        .fold<int>(0, (a, b) => a + b);
    final ownerCount = [
      ownerPunctuality,
      ownerCare,
      ownerBehavior
    ].whereType<int>().length;
    if (ownerCount == 3) {
      final ownerAvg = ownerMean / 3;
      if (shopRating == 1 && ownerAvg >= 4) {
        signals.add('Revenge pattern: customer 1-star, owner 4+');
      }
      if (shopRating == 5 && ownerAvg <= 2) {
        signals.add('Revenge pattern: customer 5-star, owner 2 or less');
      }
    }
    return AdminReview(
      id: id,
      bookingId: data['bookingId'] as String? ?? '',
      shopId: data['shopId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String?,
      vehicleName: data['vehicleName'] as String?,
      shopRating: shopRating,
      vehicleRating: vehicleRating,
      customerComment: data['customerComment'] as String? ?? '',
      ownerPunctuality: ownerPunctuality,
      ownerCare: ownerCare,
      ownerBehavior: ownerBehavior,
      ownerComment: data['ownerComment'] as String? ?? '',
      moderationStatus: data['moderation_status'] as String? ?? 'visible',
      moderationReason: data['moderation_reason'] as String? ?? '',
      signals: signals,
    );
  }
}
