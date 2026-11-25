import 'package:flutter/material.dart';

import '../../../../core/theme/card_decoration.dart';
import '../../../../l10n/app_localizations.dart';
import 'profile_trust_card.dart';
import 'reputation_score_bar.dart';

/// Profile hub (2026-11-25): the trust section on the Profile tab.
/// It folds the Reputation view in: the trust card (score, KYC,
/// blacklist, appeal) on top, then the showrooms' ratings of this
/// customer — the same averages [CustomerReputationView] shows — with
/// a tap through to the full reputation screen. The reputation route
/// itself stays live as a deep link. With no ratings yet, the empty
/// state from the reputation screen is shown instead of bars.
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
    final care = _average('careRating');
    final punctuality = _average('punctualityRating');
    final behavior = _average('behaviorRating');
    return Column(
      children: [
        ProfileTrustCard(
          trustScore: trustScore,
          kycVerified: kycVerified,
          isBlacklisted: isBlacklisted,
          onTap: onOpenReputation,
          onAppeal: onAppeal,
        ),
        const SizedBox(height: 16),
        InkWell(
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
                    Expanded(
                      child: Text(
                        l10n.reputationShopRatings,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 14),
                if (ownerReviews.isEmpty)
                  Text(
                    l10n.reputationEmpty,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else ...[
                  ReputationScoreBar(
                      label: l10n.reputationVehicleCare,
                      ratio: care / 5,
                      score: care),
                  const SizedBox(height: 10),
                  ReputationScoreBar(
                      label: l10n.reputationPunctuality,
                      ratio: punctuality / 5,
                      score: punctuality),
                  const SizedBox(height: 10),
                  ReputationScoreBar(
                      label: l10n.reputationStaffBehavior,
                      ratio: behavior / 5,
                      score: behavior),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
