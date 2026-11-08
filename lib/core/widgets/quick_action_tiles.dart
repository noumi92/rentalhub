import 'package:flutter/material.dart';

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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // #7/#12: per-tile colour — a tinted circle
                          // behind a larger icon, so tiles read as
                          // tappable and distinct at a glance.
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (tile.color ?? colorScheme.primary)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(tile.icon,
                                size: 28,
                                color: tile.color ?? colorScheme.primary),
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
                                fontWeight: FontWeight.w800,
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
          )
          .toList(),
    );
  }
}
