import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trust/presentation/views/widgets/kyc_status_style.dart';

/// Shared hero header content for the Customer Profile hub —
/// tappable avatar with ring, name, contact line, pill Edit button,
/// and interactive Trust Score + KYC status/CTA chips.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.onEdit,
    this.onOpenDocuments,
    this.onOpenReputation,
    this.photoUrl,
    this.trustScore,
    this.kycStatus = '',
  });

  final String name;
  final String email;
  final String phone;
  final VoidCallback onEdit;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenReputation;

  /// Signed URL of the stored profile photo, if any.
  final String? photoUrl;
  final double? trustScore;

  /// '' when the customer has no KYC submission yet.
  final String kycStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final showEditLabel = MediaQuery.textScalerOf(context).scale(1) < 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              label: l10n.profileEditProfile,
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          hasPhoto ? NetworkImage(photoUrl!) : null,
                      onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                      child: !hasPhoto
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.isNotEmpty
                        ? email
                        : (phone.isNotEmpty
                            ? phone
                            : l10n.profileNotSignedInShort),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: l10n.profileEditProfile,
              child: Material(
                color: Colors.white.withValues(alpha: 0.14),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onEdit,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 36),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: showEditLabel ? 12 : 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 16),
                          if (showEditLabel) ...[
                            const SizedBox(width: 5),
                            Text(
                              l10n.profileEditShort,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeaderChip(
              icon: Icons.stars_rounded,
              label: trustScore == null
                  ? l10n.reputationTrustScoreDash
                  : l10n.profileTrustScoreValue(
                      trustScore!.toStringAsFixed(1)),
              onTap: onOpenReputation,
            ),
            if (kycStatus.isNotEmpty)
              _HeaderChip(
                icon: KycStatusStyle.icon(kycStatus),
                label: KycStatusStyle.label(l10n, kycStatus),
                iconColor: KycStatusStyle.color(brightness, kycStatus),
                onTap: onOpenDocuments,
              )
            else
              _HeaderChip(
                icon: Icons.verified_user_outlined,
                label: l10n.profileVerifyKyc,
                iconColor: AppColors.secondary,
                highlight: true,
                onTap: onOpenDocuments,
              ),
          ],
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    this.iconColor,
    this.highlight = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? AppColors.secondary.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.14);
    final border = highlight
        ? AppColors.secondary.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.25);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.white),
          const SizedBox(width: 6),
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

    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(onTap: onTap, child: content)
          : content,
    );
  }
}
