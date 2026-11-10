import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

class VerifiedBadge extends StatelessWidget {
  final String? label;
  final bool isSmall;
  final bool isVerified;

  const VerifiedBadge({
    super.key,
    this.label,
    this.isSmall = false,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Phase F: the badge copy is localized; an explicit [label]
    // still wins. English fallback for delegate-less pumps.
    final l10n = AppLocalizations.of(context);
    final verifiedLabel =
        label ?? l10n?.badgeNadraVerified ?? 'Verified';
    // An explicit [label] overrides both states: the review screen
    // passes the 'Unverified' label for an unverified shop.
    final pendingLabel =
        label ?? l10n?.statusPendingReview ?? 'Pending Review';
    final Color badgeColor = isVerified
        ? AppColors.successOnContainerFor(brightness)
        : AppColors.warningOnContainerFor(brightness);
    final Color bgColor = isVerified
        ? AppColors.successContainerFor(brightness)
        : AppColors.warningContainerFor(brightness);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.hourglass_top_rounded,
            color: badgeColor,
            size: isSmall ? 12 : 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isVerified ? verifiedLabel : pendingLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
