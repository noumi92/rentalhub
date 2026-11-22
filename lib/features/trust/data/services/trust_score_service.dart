import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../admin/domain/trust_score_calculator.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/data/datasources/review_remote_data_source.dart';

/// Admin-integration audit (2026-11-10) — the ONE place the trust
/// score is computed.
///
/// Before this, the score lived in two places that disagreed: the
/// admin panel computed it live with [TrustScoreCalculator] (base 2.5
/// + KYC + trips + ratings + punctuality + conduct, clamp 0–5), while
/// the customer app showed the stored `trust_score` on the `users`
/// doc — which nothing ever recomputed, so it sat at the 5.0 default
/// written at sign-up for every customer (a new verified customer
/// scores 3.5 live, but the app showed 5.0).
///
/// Both sides now call [compute]: the admin customer detail and the
/// customer reputation/profile/home reads. Callers keep the stored
/// value only as a fallback when this returns null (no Firestore).
/// The computation itself is unchanged from the admin detail — the
/// queries moved here verbatim, including the deposit-release-time
/// proxy for punctuality and the adverse-dispute count. Never throws.
class TrustScoreResult {
  const TrustScoreResult({
    required this.breakdown,
    required this.bookings,
    required this.completedTrips,
    required this.meanOwnerRating,
    required this.kycStatus,
    this.kycCnic,
    this.kycCnicSubmitted = false,
    this.kycLicenseSubmitted = false,
  });

  final TrustScoreBreakdown breakdown;

  /// All of the customer's bookings (the admin detail also shows
  /// them, so they travel with the result instead of being read twice).
  final List<BookingEntity> bookings;
  final int completedTrips;
  final double? meanOwnerRating;
  final String kycStatus;
  final String? kycCnic;

  /// O17: which KYC documents the customer actually submitted, from
  /// the same `kyc_documents/{uid}` read that yields [kycStatus]
  /// (CNIC front/back keys, licence key). A document counts as
  /// verified only when the whole submission is 'verified' AND the
  /// document itself was submitted — the single `status` field never
  /// says per-document, so the triage badges derive it from these.
  final bool kycCnicSubmitted;
  final bool kycLicenseSubmitted;
}

class TrustScoreService {
  final FirebaseFirestore? _firestore;

  const TrustScoreService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<TrustScoreResult?> compute(String customerId, {String? shopId}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null || customerId.isEmpty) return null;
    try {
      Map<String, dynamic>? kycData;
      try {
        final kycDoc = await firestore
            .collection('kyc_documents')
            .doc(customerId)
            .get();
        kycData = kycDoc.data();
      } catch (_) {}
      final kycStatus = kycData?['status'] as String? ?? 'missing';
      final kycCnic = kycData?['cnicNumber'] as String?;
      // O17: per-document presence on the same read — a CNIC counts
      // as submitted when either side's key is stored, a licence
      // when its key is stored. Empty strings are the queued-upload
      // placeholder (see KycRemoteDataSource), not a submission.
      final kycCnicSubmitted =
          (kycData?['cnicFrontKey'] as String? ?? '').isNotEmpty ||
              (kycData?['cnicBackKey'] as String? ?? '').isNotEmpty;
      final kycLicenseSubmitted =
          (kycData?['licenseKey'] as String? ?? '').isNotEmpty;

      var bookings = const <BookingEntity>[];
      try {
        bookings = await BookingRemoteDataSource(firestore: firestore)
            .getCustomerBookings(customerId);
      } catch (_) {}
      if (bookings.isEmpty && shopId != null && shopId.isNotEmpty) {
        try {
          final shopBookings = await BookingRemoteDataSource(firestore: firestore)
              .getShopBookings(shopId);
          bookings = shopBookings
              .where((b) => b.customerId == customerId)
              .toList();
        } catch (_) {}
      }
      final completed =
          bookings.where((b) => b.status == 'completed').toList();

      var reviews = const <Map<String, dynamic>>[];
      try {
        reviews = await ReviewRemoteDataSource(firestore: firestore)
            .getCustomerReviews(customerId, onlyOwnerRated: true);
      } catch (_) {}
      final meanRating = _meanOwnerRating(reviews);

      var onTime = 0;
      var late = 0;
      var deducted = 0;
      for (final booking in completed.take(20)) {
        try {
          final depositDoc = await firestore
              .collection('security_deposits')
              .doc(booking.bookingId)
              .get();
          final deposit = depositDoc.data();
          if (deposit == null) continue;
          if (deposit['status'] == 'deducted') deducted++;
          final released = deposit['releasedAt'];
          DateTime? releasedAt;
          if (released is Timestamp) {
            releasedAt = released.toDate();
          } else if (released is String) {
            releasedAt = DateTime.tryParse(released);
          }
          if (releasedAt == null) continue;
          if (!releasedAt.isAfter(booking.returnTime)) {
            onTime++;
          } else {
            late++;
          }
        } catch (_) {}
      }

      var adverseDisputes = 0;
      try {
        Query<Map<String, dynamic>> disputesQuery = firestore
            .collection('disputes')
            .where('customerId', isEqualTo: customerId)
            .where('status', isEqualTo: 'resolved');
        if (shopId != null && shopId.isNotEmpty) {
          disputesQuery = disputesQuery.where('shopId', isEqualTo: shopId);
        }
        final disputesSnap = await disputesQuery.get();
        for (final d in disputesSnap.docs) {
          final decision = d.data()['decision'] as String?;
          if (decision == 'full_to_owner' || decision == 'partial') {
            adverseDisputes++;
          }
        }
      } catch (_) {}

      return TrustScoreResult(
        breakdown: TrustScoreCalculator.calculate(
          kycStatus: kycStatus,
          completedTrips: completed.length,
          meanOwnerRating: meanRating,
          onTimeReturns: onTime,
          lateReturns: late,
          adverseEvents: deducted + adverseDisputes,
        ),
        bookings: bookings,
        completedTrips: completed.length,
        meanOwnerRating: meanRating,
        kycStatus: kycStatus,
        kycCnic: kycCnic,
        kycCnicSubmitted: kycCnicSubmitted,
        kycLicenseSubmitted: kycLicenseSubmitted,
      );
    } catch (_) {
      return null;
    }
  }

  double? _meanOwnerRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return null;
    var sum = 0.0;
    var count = 0;
    for (final r in reviews) {
      for (final key in ['punctualityRating', 'careRating', 'behaviorRating']) {
        final v = (r[key] as num?)?.toDouble();
        if (v != null) {
          sum += v;
          count++;
        }
      }
    }
    if (count == 0) return null;
    return sum / count;
  }
}
