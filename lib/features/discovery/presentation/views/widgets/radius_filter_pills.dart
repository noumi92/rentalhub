import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// The [FloatingRadiusControl] positioned over the map canvas:
/// bottom-center, above the preview card or the empty banner
/// ([bottom] is that clearance — the preview card itself is a
/// `Positioned` this file cannot move, so the caller passes the
/// offset). A widget returning a [Positioned], like
/// [MapShopPreviewCard], so it must be a direct child of the Stack.
class FloatingRadiusOverlay extends StatelessWidget {
  const FloatingRadiusOverlay({
    super.key,
    required this.bottom,
    required this.selectedRadiusKm,
    required this.onRadiusSelected,
  });

  final double bottom;
  final double selectedRadiusKm;
  final ValueChanged<double> onRadiusSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Center(
        child: FloatingRadiusControl(
          selectedRadiusKm: selectedRadiusKm,
          onRadiusSelected: onRadiusSelected,
        ),
      ),
    );
  }
}

/// F-R1: the map radius control, floating over the map (bottom-center,
/// above the preview card) instead of sitting in the chrome stack
/// above it — radius is a map concern, not a list concern. A compact
/// `Radius: 3 km` chip opening the same 1/2/3/5 km choice as a small
/// menu. Selected radius wears the single navy token (DS-1:
/// [AppColors.primary] fill + white label); the menu marks the
/// selected radius with a checkmark.
class FloatingRadiusControl extends StatelessWidget {
  final double selectedRadiusKm;
  final ValueChanged<double> onRadiusSelected;
  final bool filterActive;
  final VoidCallback? onClearRadius;

  const FloatingRadiusControl({
    super.key,
    required this.selectedRadiusKm,
    required this.onRadiusSelected,
    this.filterActive = false,
    this.onClearRadius,
  });

  static const List<double> _radii = [1.0, 2.0, 3.0, 5.0, 10.0, 25.0];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<double>(
        tooltip: l10n.shops_radiusChip(
            selectedRadiusKm.toInt().toString()),
        onSelected: (value) {
          if (value <= 0) {
            onClearRadius?.call();
          } else {
            onRadiusSelected(value);
          }
        },
        itemBuilder: (context) => [
          if (onClearRadius != null)
            PopupMenuItem<double>(
              value: 0,
              child: Row(
                children: [
                  Expanded(child: Text(l10n.filterAll)),
                  if (!filterActive)
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ..._radii.map((km) => PopupMenuItem<double>(
                value: km,
                child: Row(
                  children: [
                    Expanded(child: Text('${km.toInt()} km')),
                    if (km == selectedRadiusKm &&
                        (onClearRadius == null || filterActive))
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              )),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.radar_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.shops_radiusChip(
                    selectedRadiusKm.toInt().toString()),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
