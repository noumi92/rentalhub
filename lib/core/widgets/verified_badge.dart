import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class VerifiedBadge extends StatelessWidget {
  final String label;
  final bool isSmall;
  final bool isVerified;

  const VerifiedBadge({
    super.key,
    this.label = 'NADRA Verified',
    this.isSmall = false,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeColor =
        isVerified ? AppColors.accentSuccess : AppColors.warning;
    final Color bgColor =
        isVerified ? AppColors.successContainer : AppColors.warningContainer;

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
              isVerified ? label : 'Pending Review',
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
