/// Phase C (C3) — the platform trust-score formula, fixed and
/// documented. Decision D4 (weights) was taken with the recommendation
/// at build time: the formula below is the fixed rule, not tuned ad hoc
/// later.
///
/// Score (0–5) = clamp(base + kyc + trips + ratings + punctuality +
/// conduct, 0, 5), where:
/// - base 2.5 — every customer starts here.
/// - kyc: verified +1.0, submitted +0.5, missing 0.
/// - trips: +0.1 per completed trip, max +0.5.
/// - ratings: (mean owner rating − 3.0) × 0.3, clamped −0.6..+0.6;
///   no ratings yet → 0.
/// - punctuality: (on-time returns − late returns) × 0.1, clamped
///   −0.5..+0.5; no completed trips → 0. "On time" is approximated
///   from the deposit release time vs the booking's scheduled return
///   time, because the app records no separate actual-return timestamp.
/// - conduct: −0.5 per confirmed damage deduction or adverse dispute
///   decision, floor −1.0; none → 0.
///
/// A verified new customer scores 3.5. A perfect record scores 5.0.
/// The breakdown is shown on the customer detail screen, so an admin
/// can see exactly why a score is what it is.
class TrustScoreBreakdown {
  const TrustScoreBreakdown({
    required this.base,
    required this.kyc,
    required this.trips,
    required this.ratings,
    required this.punctuality,
    required this.conduct,
    required this.total,
  });

  final double base;
  final double kyc;
  final double trips;
  final double ratings;
  final double punctuality;
  final double conduct;
  final double total;
}

abstract final class TrustScoreCalculator {
  static TrustScoreBreakdown calculate({
    required String kycStatus,
    required int completedTrips,
    double? meanOwnerRating,
    required int onTimeReturns,
    required int lateReturns,
    required int adverseEvents,
  }) {
    const base = 2.5;
    final kyc = switch (kycStatus) {
      'verified' => 1.0,
      // 'resubmitted' is a verified record waiting for re-review:
      // it scores like a pending submission, not like no KYC.
      'submitted' || 'resubmitted' => 0.5,
      _ => 0.0,
    };
    final trips = (completedTrips * 0.1).clamp(0.0, 0.5);
    final ratings = meanOwnerRating == null
        ? 0.0
        : ((meanOwnerRating - 3.0) * 0.3).clamp(-0.6, 0.6);
    final punctuality = completedTrips == 0
        ? 0.0
        : ((onTimeReturns - lateReturns) * 0.1).clamp(-0.5, 0.5);
    final conduct = (-0.5 * adverseEvents).clamp(-1.0, 0.0);
    final total =
        (base + kyc + trips + ratings + punctuality + conduct)
            .clamp(0.0, 5.0);
    return TrustScoreBreakdown(
      base: base,
      kyc: kyc,
      trips: trips,
      ratings: ratings,
      punctuality: punctuality,
      conduct: conduct,
      total: total,
    );
  }
}
