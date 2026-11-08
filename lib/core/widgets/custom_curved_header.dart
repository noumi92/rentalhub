import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../l10n/app_localizations.dart';
import 'verified_badge.dart';

/// Phase D (D1): one header system. Exactly two header heights exist:
/// [CustomCurvedHeaderVariant.hero] (230, rulebook §4.3) for screens
/// whose hero card overlaps the header, and
/// [CustomCurvedHeaderVariant.compact] (100) for every title-only
/// screen. Callers pass a variant, never a height.
enum CustomCurvedHeaderVariant { hero, compact }

class CustomCurvedHeader extends StatelessWidget {
  final Widget titleWidget;
  final Widget? leadingWidget;

  /// Back policy: when no explicit [leadingWidget] is given, the header
  /// renders a back button automatically iff the current route can pop,
  /// and never at a branch root. Inside a StatefulShellRoute the nearest
  /// Navigator is the branch navigator, which holds a single route at a
  /// tab root (so `canPop` is false there) and one per pushed screen (so
  /// it is true). An explicit [leadingWidget] always wins; set
  /// [showBackButton] to false to suppress the automatic button.
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? bottomWidget;
  final CustomCurvedHeaderVariant variant;
  final bool showProfileGreeting;
  final String userName;
  final String? urduGreeting;
  final bool isVerified;
  final VoidCallback? onNotificationTap;

  const CustomCurvedHeader({
    super.key,
    required this.titleWidget,
    this.leadingWidget,
    this.showBackButton = true,
    this.actions,
    this.bottomWidget,
    this.variant = CustomCurvedHeaderVariant.hero,
    this.showProfileGreeting = false,
    // Phase A (A5): no fake identity. Callers must pass the signed-in
    // user's real name; an empty name renders a neutral greeting and an
    // unverified badge instead of pretending to be a fake demo user.
    this.userName = '',
    // Phase F: no hardcoded Urdu default — the greeting resolves from
    // AppLocalizations at render time (English fallback for
    // delegate-less pumps). No call site passes this today.
    this.urduGreeting,
    this.isVerified = false,
    this.onNotificationTap,
  });

  /// The automatic back button, or null when this screen must not show
  /// one (a tab root, or [showBackButton] is false). Uses the nearest
  /// Navigator so it works in a shell branch, on a plain route, and in
  /// tests; [Navigator.maybeOf] returns null (no button) when the header
  /// is built outside any Navigator.
  Widget? _autoBackButton(BuildContext context) {
    if (!showBackButton) return null;
    if (Navigator.maybeOf(context)?.canPop() != true) return null;
    // Phase F: localized tooltip (English fallback for
    // delegate-less pumps).
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n?.back ?? 'Back',
      icon: const Icon(Icons.arrow_back_ios_new_rounded,
          color: Colors.white, size: 20),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phase F: greeting + notifications tooltip are localized
    // (English fallback for delegate-less pumps).
    final l10n = AppLocalizations.of(context);
    final greeting = userName.isNotEmpty
        ? l10n?.headerGreeting(userName) ?? 'Hi, $userName'
        : l10n?.headerGreetingFallback ?? 'Hi there';
    final urduGreetingText =
        urduGreeting ?? l10n?.headerUrduGreeting ?? 'اسلام علیکم';
    final topPadding = MediaQuery.of(context).padding.top;
    // D1: the height comes from the variant, never from the caller.
    final double height = variant == CustomCurvedHeaderVariant.hero
        ? AppDimensions.headerHeight
        : AppDimensions.headerCompactHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Explicit leadingWidget wins; otherwise the automatic back button
    // decides from canPop (renders on pushed screens, never at a tab root).
    final Widget? effectiveLeading = leadingWidget ?? _autoBackButton(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height + topPadding),
      decoration: BoxDecoration(
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
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.headerBottomRadius),
        ),
        child: CustomPaint(
          painter: CurvedGradientHeaderPainter(isDark: isDark),
          child: Padding(
            padding: EdgeInsets.only(
              top: topPadding + 10,
              left: AppDimensions.paddingHorizontal,
              right: AppDimensions.paddingHorizontal,
              bottom: 32, // Extra bottom space for -28.0 card overlap
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
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(
                                  greeting,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  '($urduGreetingText)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: AppColors.primaryContainer,
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
                        tooltip: l10n?.notifications ?? 'Notifications',
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
                                  color: AppColors.secondary,
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
                    if (effectiveLeading != null) effectiveLeading,
                    if (effectiveLeading != null) const SizedBox(width: 12),
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
          ),
        ),
      ),
    );
  }
}

/// Organic layered curved gradient painter inspired by modern fintech header design
/// (ui_ref.jpg), utilizing RentalHub's brand palette (Midnight Navy & Indigo).
class CurvedGradientHeaderPainter extends CustomPainter {
  final bool isDark;

  const CurvedGradientHeaderPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Base gradient fill (rulebook §4.3): #16194F → #242875 light,
    // #0B0D26 → #16194F dark.
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [AppColors.primaryDarkOnDark, AppColors.primaryDark]
          : const [AppColors.primaryDark, AppColors.headerGradientEnd],
    );

    final basePaint = Paint()..shader = baseGradient.createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Large top-right organic sweeping curve (matching ui_ref.jpg curved layer)
    final arcPaint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.95, -0.6),
        radius: 1.15,
        colors: [
          (isDark ? AppColors.headerArcDark : AppColors.headerArcLight)
              .withValues(alpha: 0.55),
          (isDark ? AppColors.headerArcDarkSoft : AppColors.headerArcLightSoft)
              .withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    final path1 = Path();
    path1.moveTo(size.width * 0.35, 0);
    path1.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.65,
      size.width,
      size.height * 0.88,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, arcPaint1);

    // 3. Secondary soft layered organic curve sweeping down from center-right
    final arcPaint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          (isDark ? AppColors.headerArc2Dark : AppColors.headerArc2Light)
              .withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ).createShader(rect);

    final path2 = Path();
    path2.moveTo(size.width * 0.58, 0);
    path2.cubicTo(
      size.width * 0.68,
      size.height * 0.42,
      size.width * 0.88,
      size.height * 0.72,
      size.width,
      size.height * 0.52,
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, arcPaint2);

    // 4. Subtle top-left ambient illumination behind user avatar / brand logo
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.85, -0.7),
        radius: 0.65,
        colors: [
          (isDark ? AppColors.headerArcDark : AppColors.headerGlowLight)
              .withValues(alpha: 0.40),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CurvedGradientHeaderPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Wrapper that applies the DOC-2 mandated -28.0 negative top margin overlap
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
