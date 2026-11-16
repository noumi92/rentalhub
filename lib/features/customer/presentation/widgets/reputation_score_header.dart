import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/card_decoration.dart';
import '../../../../l10n/app_localizations.dart';

/// Customer pass (2026-11-16): the reputation score hero — the
/// customer's overall score, trust score and review count. Extracted
/// from [CustomerReputationView] so the view stays under the
/// 250-line cap. Canonical showroom card (surface, 1px hairline,
/// radius 16, elevation 1.5).
class ReputationScoreHeader extends StatelessWidget {
  const ReputationScoreHeader({
    super.key,
    required this.overall,
    required this.trustScore,
    required this.reviewCount,
  });

  final double? overall;
  final double? trustScore;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Locals so the null checks below promote (fields do not).
    final overallValue = overall;
    final trustValue = trustScore;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardDecoration.of(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentSuccess.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded,
                color: AppColors.successTextFor(
                    Theme.of(context).brightness),
                size: 50),
          ),
          const SizedBox(height: 12),
          Text(
            overallValue == null
                ? '— / 5.0'
                : '${overallValue.toStringAsFixed(1)} / 5.0',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            trustValue == null
                ? l10n.reputationTrustScoreDash
                : l10n.reputationTrustScoreValue(
                    trustValue.toStringAsFixed(1)),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.successTextFor(
                    Theme.of(context).brightness)),
          ),
          const SizedBox(height: 8),
          Text(
            reviewCount == 0
                ? l10n.reputationEmpty
                : l10n.reputationBasedOnReviews(reviewCount),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
