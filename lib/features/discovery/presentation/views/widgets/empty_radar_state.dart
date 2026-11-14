import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../../l10n/app_localizations.dart';

/// #3: radius-aware empty state. [currentRadiusKm] is the radius the
/// list is already on (radii are [1, 2, 3, 5] km); below the maximum
/// the expand button steps to the next radius via [onExpandRadius],
/// and at the 5.0 km maximum the button is replaced by the no-shops
/// message + a "Browse all shops" action opening the full-screen map.
class EmptyRadarState extends StatelessWidget {
  final double currentRadiusKm;
  final VoidCallback onExpandRadius;

  const EmptyRadarState({
    super.key,
    required this.currentRadiusKm,
    required this.onExpandRadius,
  });

  static const double maxRadiusKm = 5.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMax = currentRadiusKm >= maxRadiusKm;
    // #3: the button names the radius it will step to (1 -> 2 -> 3
    // -> 5 km), never the radius already shown.
    const radii = [1.0, 2.0, 3.0, 5.0];
    final nextRadius =
        radii.firstWhere((r) => r > currentRadiusKm, orElse: () => 5.0);
    return Container(
      padding: const EdgeInsets.all(24),
      // Canonical borderless card look (soft shadow, no dark border).
      decoration: AppCardDecoration.of(context, radius: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.radar_rounded,
              size: 34,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isMax
                ? l10n.emptyRadarNoShopsTitle
                : l10n.emptyRadarNoShops(currentRadiusKm.toInt()),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            isMax
                ? l10n.emptyRadarNoShopsSubtitle
                : l10n.emptyRadarExpandHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          if (isMax)
            OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.customerHomeMap),
              style: OutlinedButton.styleFrom(
                // 48dp minimum; the button grows instead of clipping
                // when the Urdu label wraps to two lines at large
                // text scale.
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.map_rounded, size: 16),
              label: Text(
                l10n.emptyRadarBrowseAll,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: onExpandRadius,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.zoom_out_map_rounded, size: 16),
              label: Text(
                l10n.emptyRadarExpandToKm(nextRadius.toInt()),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
