import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/card_decoration.dart';
import '../../../../l10n/app_localizations.dart';

/// H1: the profile's trust card — the customer's real trust score from
/// their `users` record, their real KYC state, and their real blacklist
/// state. Nothing here is hardcoded: an unknown score shows '—'.
class ProfileTrustCard extends StatelessWidget {
  const ProfileTrustCard({
    super.key,
    required this.trustScore,
    required this.kycVerified,
    required this.isBlacklisted,
    this.onTap,
    this.onAppeal,
  });

  final double? trustScore;
  final bool kycVerified;
  final bool isBlacklisted;
  final VoidCallback? onTap;

  /// Shown only when the customer is blacklisted (the caller passes
  /// it exactly then): opens the blacklist appeal form.
  final VoidCallback? onAppeal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppCardDecoration.of(context, radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    AppColors.accentSuccess.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stars_rounded,
                  color: AppColors.successTextFor(Theme.of(context).brightness), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trustScore == null
                        ? l10n.reputationTrustScoreDash
                        : l10n.profileTrustScoreValue(trustScore!.toStringAsFixed(1)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${kycVerified ? l10n.trustKycVerified : l10n.trustKycPending} • '
                    '${isBlacklisted ? l10n.trustBlacklisted : l10n.trustNoBlacklist}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
            if (onAppeal != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
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
          ],
        ),
      ),
    );
  }
}
