import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Shared card (card rework, 2026-11-10): the one card look for both
/// modules — theme surface, elevation 1.5, soft shadow, 1 px hairline
/// border in `borderSubtle` / `borderDark` (showroom redesign Phase 0
/// + Phase 5, 2026-11-16). The explicit shape carries the hairline
/// side because an explicit shape otherwise overrides the theme's
/// `CardThemeData` side; the elevation stays null so the theme's 1.5
/// applies.
///
/// This is a thin wrapper over [Card]: when [elevation]/[color]/
/// [borderRadius] are left null the theme's `CardThemeData` applies
/// (surface, elevation 1.5, hairline, rounded shape), so every card in
/// the app changes together. Pass [onTap] for a tappable card; the
/// ripple is clipped to the card's rounded shape.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
    this.elevation,
    this.color,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final Color? color;
  final double? borderRadius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppDimensions.cardRadius;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    return Card(
      elevation: elevation,
      color: color,
      margin: margin,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: dark ? AppColors.borderDark : AppColors.borderSubtle,
        ),
      ),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: content,
            ),
    );
  }
}
