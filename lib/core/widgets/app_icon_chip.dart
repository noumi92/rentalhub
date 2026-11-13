import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Eye-catching icon chip (#12): a circular ~40dp chip with a tinted
/// background behind the icon, so header actions and quick-action tiles
/// read as tappable instead of bare glyphs. The background defaults to
/// the icon colour at ~15% alpha over the surface; callers on a navy
/// header pass an explicit white-tinted background + white icon colour.
/// [badgeCount] > 0 shows a count badge; 0 shows a plain dot.
class AppIconChip extends StatelessWidget {
  const AppIconChip({
    super.key,
    required this.icon,
    this.onPressed,
    this.background,
    this.iconColor,
    this.tooltip,
    this.badgeCount,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? iconColor;
  final String? tooltip;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ?? scheme.primary;
    final resolvedBackground =
        background ?? resolvedIconColor.withValues(alpha: 0.15);
    final chip = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: resolvedBackground,
        shape: BoxShape.circle,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 22, color: resolvedIconColor),
          if (badgeCount != null)
            Positioned(
              right: -2,
              top: -2,
              child: badgeCount! > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        // Audit SH-N2: was raw Colors.red — the token
                        // is accentDanger.
                        color: AppColors.accentDanger,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Text(
                        '$badgeCount',
                        // Audit SH-N2: the count was a hardcoded
                        // fontSize: 10, below the 11 sp labelSmall
                        // floor. It now uses the labelSmall slot.
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    )
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentDanger,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
        ],
      ),
    );
    final tappable = onPressed == null
        ? chip
        // Audit fix: the visual chip stays 40 dp, but the hit area is
        // padded to the §4.6 48 dp minimum (the InkWell fills the
        // 48 dp box; the 40 dp chip sits centred inside it).
        : SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onPressed,
                child: Center(child: chip),
              ),
            ),
          );
    if (tooltip == null) return tappable;
    return Tooltip(message: tooltip!, child: tappable);
  }
}

/// Tappable avatar circle showing the user's initial (#5): the same
/// 40dp chip treatment as [AppIconChip], but with a letter instead of
/// an icon glyph.
class AppInitialChip extends StatelessWidget {
  const AppInitialChip({
    super.key,
    required this.initial,
    this.onPressed,
    this.background,
    this.foreground,
    this.tooltip,
  });

  final String initial;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial.isEmpty ? 'U' : initial[0].toUpperCase(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: foreground ?? Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
    final tappable = onPressed == null
        ? chip
        // Same 48 dp hit area as [AppIconChip]: the 40 dp visual
        // stays, centred inside the 48 dp tap target.
        : SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onPressed,
                child: Center(child: chip),
              ),
            ),
          );
    if (tooltip == null) return tappable;
    return Tooltip(message: tooltip!, child: tappable);
  }
}
