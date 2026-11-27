import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/trust_score_calculator.dart';
import 'admin_list_card.dart';
import 'admin_status_chip.dart';

/// The C3 trust-score breakdown on the customer detail screen: the
/// computed (live) score and each component with its contribution.
/// A component of 0.0 means that input has no data yet (for example
/// no owner ratings), not that the customer failed it.
///
/// Phase 4 (4.4b) — live-score-only: the older stored
/// `trust_score` is no longer shown here (it used to appear as
/// "Previously stored: X.X" and genuinely disagreed with the live
/// score before — live 3.5 vs stored 5.0). The stored value stays
/// in the data layer but out of the UI entirely.
class CustomerTrustBreakdown extends StatelessWidget {
  const CustomerTrustBreakdown({
    super.key,
    required this.breakdown,
    required this.completedTrips,
    required this.meanOwnerRating,
    required this.kycStatus,
  });

  final TrustScoreBreakdown breakdown;
  final int completedTrips;
  final double? meanOwnerRating;
  final String kycStatus;

  /// The stored KYC status ('missing' / 'pending' / 'verified' /
  /// 'rejected') as a human label, never the raw stored string
  /// (AD-M9, customer part).
  static String _kycLabel(String status, AppLocalizations? l10n) {
    final localized = switch (status) {
      'missing' => l10n?.adminAuditKycNotSubmitted,
      'pending' => l10n?.adminAuditKycPending,
      'verified' => l10n?.adminAuditKycVerified,
      'rejected' => l10n?.adminAuditKycRejected,
      _ => null,
    };
    if (localized != null) return localized;
    return humanizeStatus(status, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: adminCardShape(context),
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
                Expanded(
                  child: Text(l10n?.admin2_trustTitle ?? 'Trust score',
                      style: TextStyle(
                          fontSize: 15,
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
                        fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n?.admin2_trustKycLine(_kycLabel(kycStatus, l10n), completedTrips) ?? 'KYC: ${_kycLabel(kycStatus, l10n)} • $completedTrips completed trip(s) • '}'
              '${l10n?.admin2_trustOwnerRating(meanOwnerRating == null ? (l10n.admin2_trustRatingNone) : meanOwnerRating!.toStringAsFixed(1)) ?? 'Owner rating: ${meanOwnerRating == null ? 'none yet' : meanOwnerRating!.toStringAsFixed(1)}'}',
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _bar(context, l10n?.admin2_trustBase ?? 'Base', breakdown.base, 2.5),
            _bar(context, l10n?.admin2_trustKyc ?? 'KYC', breakdown.kyc, 1.0),
            _bar(context, l10n?.admin2_trustTrips ?? 'Trips', breakdown.trips, 0.5),
            _bar(context, l10n?.admin2_trustRatings ?? 'Ratings', breakdown.ratings, 0.6),
            _bar(context, l10n?.admin2_trustPunctuality ?? 'Punctuality', breakdown.punctuality, 0.5),
            _bar(context, l10n?.admin2_trustConduct ?? 'Conduct', breakdown.conduct, 1.0),
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
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
