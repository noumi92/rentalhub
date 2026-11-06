import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

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
  });

  final double? trustScore;
  final bool kycVerified;
  final bool isBlacklisted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    AppColors.emeraldGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded,
                  color: AppColors.emeraldGreen, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trustScore == null
                        ? 'Trust Score: —'
                        : 'Trust Score: ${trustScore!.toStringAsFixed(1)} / 5.0',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnightNavy),
                  ),
                  Text(
                    '${kycVerified ? 'KYC verified' : 'KYC pending'} • '
                    '${isBlacklisted ? 'Flagged on blacklist' : 'No blacklist record'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
