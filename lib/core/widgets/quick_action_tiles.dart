import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// E1: one quick-action tile — an icon above a short label, in the
/// HBL banking reference pattern. The tile is pure data; the row widget
/// below renders a list of them, so customer Home and owner Dashboard
/// share the same component instead of each hand-rolling one.
/// [color] is the tile's per-destination accent (#7/#12): the icon
/// sits in a tinted circle of that colour, so a colour means the same
/// destination everywhere. Null keeps the theme primary.
class QuickActionTile {
  const QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
}

/// E1: a row of [QuickActionTile]s, one per action, each with a
/// minimum 48x48 touch target (the tile is 72dp tall and each column
/// is at least a quarter of the screen width). Colours and text styles
/// come from the theme only, so the tiles stay readable in dark mode.
class QuickActionTiles extends StatelessWidget {
  const QuickActionTiles({super.key, required this.tiles});

  final List<QuickActionTile> tiles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    // Item 4: the tile colour is the icon colour on a 15% tint of
    // itself. The raw fills fail as icons in light mode (accentSuccess
    // 2.54:1, warning 2.15:1, vs the 3:1 non-text minimum), so those
    // icons use the readable text variants; secondary (3.29:1) and
    // the other accents already pass, so they stay as-is.
    Color iconColor(Color? color) {
      final c = color ?? colorScheme.primary;
      if (c == AppColors.primary || c == AppColors.primaryOnDark) {
        return AppColors.primaryTextFor(brightness);
      }
      if (c == AppColors.accentSuccess) {
        return AppColors.successTextFor(brightness);
      }
      if (c == AppColors.warning) {
        return AppColors.warningTextFor(brightness);
      }
      return c;
    }
    return Row(
      children: tiles
          .map(
            (tile) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('quick-action-${tile.label}'),
                    onTap: tile.onTap,
                    // E3: a minimum height, not a fixed one — at 200%
                    // text scale the two-line label needs more than
                    // 72dp, and the fixed SizedBox overflowed by 24px.
                    // The tile is still >= 48dp tall at every scale.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 72),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: iconColor(tile.color)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(tile.icon,
                                  size: 28, color: iconColor(tile.color)),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                tile.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
