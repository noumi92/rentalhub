import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

/// The one card look for RentalHub (card rework, 2026-11-10).
///
/// Cards lift off the screen on a different background with a soft
/// shadow — never a dark/grey border. The old look drew every card
/// with `Border.all(color: Theme.of(context).dividerColor)`; in the
/// Material 3 defaults that resolves to `colorScheme.outline`, a
/// mid-grey that read as a dark outline around every white card, in
/// both modules. The new look is:
///
/// * light: white card (`colorScheme.surface`) on the `#F8FAFC`
///   screen background, soft black shadow (8% alpha);
/// * dark: `#13152C` card on the `#0A0B1A` screen background, deeper
///   shadow (45% alpha) — the card is a lighter slab than the screen,
///   so it still lifts without a border.
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
  /// soft shadow, no border. [radius] defaults to the theme card
  /// radius ([AppDimensions.cardRadius]).
  static BoxDecoration of(
    BuildContext context, {
    double radius = AppDimensions.cardRadius,
    Color? color,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: boxShadow ?? shadow(context),
    );
  }
}
