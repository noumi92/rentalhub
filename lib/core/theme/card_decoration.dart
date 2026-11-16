import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// The one card look for RentalHub (card rework, 2026-11-10; showroom
/// redesign Phase 0, 2026-11-16).
///
/// Cards lift off the screen on a different background with a soft
/// shadow, plus a 1 px hairline border in `borderSubtle` (`#E2E8F0`
/// light / `#23274D` dark). The 2026-11-10 look was borderless — the
/// old `Border.all(color: dividerColor)` read as a dark outline
/// because it resolved to M3 `outline`, a mid-grey; the showroom
/// guide deliberately reintroduces the border as the subtle token,
/// with elevation 1.5 and radius 16. The look is:
///
/// * light: white card (`colorScheme.surface`) on the `#F8FAFC`
///   screen background, soft black shadow (8% alpha);
/// * dark: `#13152C` card on the `#0A0B1A` screen background, deeper
///   shadow (45% alpha) — the card is a lighter slab than the screen,
///   so it still lifts.
///
/// Use [of] for `Container`-based cards and [shadow] when a
/// decoration already sets its own colour/radius. `Card` widgets get
/// the same look from `AppTheme`'s `CardThemeData` and need no code.
class AppCardDecoration {
  /// Soft lift shadow for a card, brightness-aware. Dark mode needs a
  /// much stronger alpha because the shadow falls on a near-black
  /// screen; light mode stays subtle so the card does not look dirty.
  static List<BoxShadow> shadow(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.45 : 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// The canonical card decoration: theme surface, rounded corners,
  /// 1 px `borderSubtle` hairline, soft shadow. [radius] defaults to
  /// the theme card radius ([AppDimensions.cardRadius]).
  static BoxDecoration of(
    BuildContext context, {
    double radius = AppDimensions.cardRadius,
    Color? color,
    List<BoxShadow>? boxShadow,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      border: Border.all(
        color: dark ? AppColors.borderDark : AppColors.borderSubtle,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: boxShadow ?? shadow(context),
    );
  }
}
