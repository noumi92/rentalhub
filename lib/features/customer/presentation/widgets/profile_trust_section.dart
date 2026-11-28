import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/card_decoration.dart';
import '../../../../l10n/app_localizations.dart';
import 'reputation_score_bar.dart';

/// Unified Trust & Reputation card on the Customer Profile tab.
/// Combines the trust summary (score, KYC, blacklist, appeal) and
/// showroom ratings into one card with a single RTL-aware chevron.
class ProfileTrustSection extends StatelessWidget {
  const ProfileTrustSection({
    super.key,
    required this.trustScore,
    required this.kycVerified,
    required this.isBlacklisted,
    required this.onOpenReputation,
    required this.onAppeal,
    required this.ownerReviews,
  });

  final double? trustScore;
  final bool kycVerified;
  final bool isBlacklisted;
  final VoidCallback? onOpenReputation;
  final VoidCallback? onAppeal;
  final List<Map<String, dynamic>> ownerReviews;

  double _average(String field) {
    final values = ownerReviews
        .map((r) => (r[field] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final care = _average('careRating');
    final punctuality = _average('punctualityRating');
    final behavior = _average('behaviorRating');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenReputation,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppCardDecoration.of(context, radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSuccess.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      color: AppColors.successTextFor(brightness),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trustScore == null
                              ? l10n.reputationTrustScoreDash
                              : l10n.profileTrustScoreValue(
                                  trustScore!.toStringAsFixed(1)),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${kycVerified ? l10n.trustKycVerified : l10n.trustKycPending} • '
                          '${isBlacklisted ? l10n.trustBlacklisted : l10n.trustNoBlacklist}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isRtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (onAppeal != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: onAppeal,
                    icon: const Icon(Icons.gavel_rounded, size: 18),
                    label: Text(l10n.appealButton),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                  ),
                ),
              ],
              const Divider(height: 24, thickness: 0.8),
              Text(
                l10n.reputationShopRatings,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (ownerReviews.isEmpty)
                Text(
                  l10n.reputationEmpty,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else ...[
                ReputationScoreBar(
                  label: l10n.reputationVehicleCare,
                  ratio: care / 5,
                  score: care,
                ),
                const SizedBox(height: 10),
                ReputationScoreBar(
                  label: l10n.reputationPunctuality,
                  ratio: punctuality / 5,
                  score: punctuality,
                ),
                const SizedBox(height: 10),
                ReputationScoreBar(
                  label: l10n.reputationStaffBehavior,
                  ratio: behavior / 5,
                  score: behavior,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
