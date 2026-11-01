import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'verified_badge.dart';

class CustomCurvedHeader extends StatelessWidget {
  final Widget titleWidget;
  final Widget? leadingWidget;
  final List<Widget>? actions;
  final Widget? bottomWidget;
  final double height;
  final bool showProfileGreeting;
  final String userName;
  final String urduGreeting;
  final bool isVerified;
  final VoidCallback? onNotificationTap;

  const CustomCurvedHeader({
    super.key,
    required this.titleWidget,
    this.leadingWidget,
    this.actions,
    this.bottomWidget,
    this.height = AppDimensions.headerHeight,
    this.showProfileGreeting = false,
    this.userName = 'Ahmed Raza',
    this.urduGreeting = 'اسلام علیکم',
    this.isVerified = true,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height + topPadding),
      padding: EdgeInsets.only(
        top: topPadding + 10,
        left: AppDimensions.paddingHorizontal,
        right: AppDimensions.paddingHorizontal,
        bottom: 32, // Extra bottom space for -24.0 card overlap
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0B0D26), Color(0xFF16194F)]
              : const [AppColors.primaryDark, Color(0xFF242875)],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.headerBottomRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProfileGreeting) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sunsetOrange.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.sunsetOrange,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Hi, $userName',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '($urduGreeting)',
                            style: const TextStyle(
                              color: AppColors.textLavender,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      VerifiedBadge(isVerified: isVerified),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onNotificationTap,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      Positioned(
                        right: 1,
                        top: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.sunsetOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (leadingWidget != null) leadingWidget!,
              if (leadingWidget != null) const SizedBox(width: 12),
              Expanded(child: titleWidget),
              if (actions != null) ...actions!,
            ],
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 14),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}

/// Wrapper that applies the DOC-2 mandated -24.0 negative top margin overlap
/// so primary content cards float across the curved header baseline.
class HeaderOverlapContainer extends StatelessWidget {
  final Widget child;
  final double overlapOffset;

  const HeaderOverlapContainer({
    super.key,
    required this.child,
    this.overlapOffset = AppDimensions.headerOverlapOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, overlapOffset),
      child: child,
    );
  }
}
