import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trust/presentation/views/widgets/kyc_status_style.dart';

/// Profile hub (2026-11-25): the one shared header for the Profile
/// hub — avatar (stored photo when the customer has one, initial
/// otherwise), name, email/phone, a trust-score chip and a KYC status
/// chip. It replaces the old dead [ProfileHeader] (avatar + name +
/// edit only, never instantiated) and the inline header the profile
/// view used to build itself.
///
/// The KYC chip uses the shared [KycStatusStyle] mapping, so the hub,
/// the KYC banner and the Home card can never disagree about a
/// status. The chip is only shown once a KYC record exists.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.onEdit,
    this.photoUrl,
    this.trustScore,
    this.kycStatus = '',
  });

  final String name;
  final String email;
  final String phone;
  final VoidCallback onEdit;

  /// Signed URL of the stored profile photo, if any.
  final String? photoUrl;
  final double? trustScore;

  /// '' when the customer has no KYC submission yet.
  final String kycStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              backgroundImage:
                  photoUrl != null && photoUrl!.isNotEmpty
                      ? NetworkImage(photoUrl!)
                      : null,
              // CircleAvatar asserts when an error handler is set
              // with no image — only attach it when a photo exists.
              onBackgroundImageError:
                  photoUrl != null && photoUrl!.isNotEmpty
                      ? (_, __) {}
                      : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(
                    email.isNotEmpty
                        ? email
                        : (phone.isNotEmpty
                            ? phone
                            : l10n.profileNotSignedInShort),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryContainer),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 20),
              tooltip: l10n.profileEditProfile,
              onPressed: onEdit,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              icon: Icons.stars_rounded,
              label: trustScore == null
                  ? l10n.reputationTrustScoreDash
                  : l10n.profileTrustScoreValue(
                      trustScore!.toStringAsFixed(1)),
            ),
            if (kycStatus.isNotEmpty)
              _Chip(
                icon: KycStatusStyle.icon(kycStatus),
                label: KycStatusStyle.label(l10n, kycStatus),
                color: KycStatusStyle.color(brightness, kycStatus),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          // At 200% text scale the label can exceed the Wrap run
          // width — shrink it with an ellipsis instead of overflowing.
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
