import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/trust_score_calculator.dart';

/// The C3 trust-score breakdown on the customer detail screen: the
/// computed score, each component with its contribution, and the older
/// stored score for comparison. A component of 0.0 means that input
/// has no data yet (for example no owner ratings), not that the
/// customer failed it.
class CustomerTrustBreakdown extends StatelessWidget {
  const CustomerTrustBreakdown({
    super.key,
    required this.breakdown,
    required this.storedScore,
    required this.completedTrips,
    required this.meanOwnerRating,
    required this.kycStatus,
  });

  final TrustScoreBreakdown breakdown;
  final double? storedScore;
  final int completedTrips;
  final double? meanOwnerRating;
  final String kycStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Mobile-first: the title flexes so the score never
                // overflows at 2.0x text scale — at 40sp the score
                // alone is ~180dp wide on a 360dp phone.
                const Expanded(
                  child: Text('Trust score',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          )),
                ),
                // The score flexes too: at 2.0x it is ~180dp wide and
                // wraps to two lines rather than overflowing the row.
                Flexible(
                  child: Text(
                    '${breakdown.total.toStringAsFixed(1)} / 5.0',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'KYC: $kycStatus • $completedTrips completed trip(s) • '
              'Owner rating: ${meanOwnerRating == null ? 'none yet' : meanOwnerRating!.toStringAsFixed(1)}'
              '${storedScore == null ? '' : ' • Stored score: ${storedScore!.toStringAsFixed(1)}'}',
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _bar(context, 'Base', breakdown.base, 2.5),
            _bar(context, 'KYC', breakdown.kyc, 1.0),
            _bar(context, 'Trips', breakdown.trips, 0.5),
            _bar(context, 'Ratings', breakdown.ratings, 0.6),
            _bar(context, 'Punctuality', breakdown.punctuality, 0.5),
            _bar(context, 'Conduct', breakdown.conduct, 1.0),
          ],
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, String label, double value, double max) {
    final ratio = max == 0 ? 0.0 : (value.abs() / max).clamp(0.0, 1.0);
    final sign = value < 0 ? '−' : '+';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style:
                    TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Theme.of(context).dividerColor,
              color: value < 0
                  ? Colors.red.shade700
                  : AppColors.accentSuccess,
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          // No fixed width: at 2.0x text scale "+1.0" is wider than
          // 44dp and the old fixed box clipped it. The bar flexes,
          // so the value takes what it needs.
          Text('$sign${value.abs().toStringAsFixed(1)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
