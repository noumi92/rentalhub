import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';


/// H2: one settings section card (title + content). Extracted from
/// [CustomerSettingsView] so the view stays under the 250-line cap.
///
/// The card IS a Material (surface, radius 16, 1 px hairline side,
/// elevation 1.5): the rows inside are ListTiles, and a ListTile
/// paints its ink on the nearest Material ancestor. When the card
/// was a Material wrapping a Container with a coloured decoration
/// (showroom redesign Phase 5), the decoration sat between the
/// Material and the ListTiles, hid the ink, and Flutter threw
/// ("ListTile background color or ink splashes may be invisible").
/// So the shape lives on the Material itself — same canonical look
/// (1 px `borderSubtle`/`borderDark` hairline, radius 16,
/// elevation 1.5), with a canvas the ink can paint on.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Material(
          color: theme.colorScheme.surface,
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: dark ? AppColors.borderDark : AppColors.borderSubtle,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ],
    );
  }
}
