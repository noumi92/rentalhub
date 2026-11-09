import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/money_format.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/domain/entities/security_deposit_entity.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../services/admin_audit_service.dart';

/// Phase D — the platform side of the admin panel: bookings, the
/// disputes centre, and reviews moderation.
///
/// D2 note: the dispute decision is stored on the dispute document
/// (`decision`, `decision_amount`, `admin_note`). The shop is notified
/// through an in-app notification record. The customer sees the
/// decision on the dispute itself — there is no customer notifications
/// feed to write to (the customer plan's D6 says no customer
/// notifications screen), so no customer-side notification record is
/// faked. The C3 trust score already counts a decision against the
/// customer (deducted deposits + adverse dispute decisions), so a
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

  Future<List<BookingModel>> getBookings({String status = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
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
    } catch (_) {
      return [];
    }
  }

  Future<BookingDetail?> getBookingDetail(String bookingId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
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
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<DisputeRecord>> getDisputes({String status = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
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
    } catch (_) {
      return [];
    }
  }

  DisputeRecord _disputeFromDoc(
      String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
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
    );
  }

  /// Decide a dispute (D2). Decision values: 'full_to_customer' |
  /// 'partial' | 'full_to_owner'. The 72 h SLA is measured from the
  /// dispute's createdAt; the view shows how long is left.
  Future<bool> decideDispute({
    required String disputeId,
    required String decision,
    required int decisionAmount,
    required String adminNote,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      final doc =
          await firestore.collection('disputes').doc(disputeId).get();
      final data = doc.data();
      if (data == null) return false;
      await firestore.collection('disputes').doc(disputeId).update({
        'status': 'resolved',
        'decision': decision,
        'decision_amount': decisionAmount,
        'admin_note': adminNote,
        'resolved_at': FieldValue.serverTimestamp(),
      });
      final shopId = data['shopId'] as String?;
      final bookingId = data['bookingId'] as String?;
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

  /// All review documents with their moderation state and the
  /// auto-check signals (D3). A review enters a queue when it has a
  /// signal; the admin's decision is what makes it hidden, not the
  /// signal itself.
  Future<List<AdminReview>> getReviews() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('reviews')
          .limit(200)
          .get();
      return snap.docs
          .map((d) => AdminReview.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Keep / Hide / Ask-to-edit / Warn (D3). Status values: 'visible' |
  /// 'hidden' | 'edit_requested' | 'warned'.
  Future<bool> setReviewModeration({
    required String reviewId,
    required String status,
    required String reason,
  }) async {
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
  });

  final BookingEntity booking;
  final SecurityDepositEntity? deposit;
  final String? agreementPdfUrl;
  final HandoverSummary? handover;
  final DisputeRecord? dispute;
  final List<AdminMessage> messages;
}

/// The handover record for a booking (pickup checklist + odometer).
class HandoverSummary {
  const HandoverSummary({
    required this.initialOdometer,
    required this.fuelLevel,
    required this.damageNotes,
    required this.agreementPdfUrl,
  });

  final int initialOdometer;
  final String fuelLevel;
  final List<String> damageNotes;
  final String? agreementPdfUrl;

  factory HandoverSummary.fromMap(Map<String, dynamic> data) {
    return HandoverSummary(
      initialOdometer: (data['initialOdometer'] as num?)?.toInt() ?? 0,
      fuelLevel: data['fuelLevel'] as String? ?? '',
      damageNotes:
          List<String>.from(data['damageNotes'] as List? ?? const []),
      agreementPdfUrl: data['agreementPdfUrl'] as String?,
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
