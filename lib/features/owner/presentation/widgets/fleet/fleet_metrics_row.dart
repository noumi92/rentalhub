import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import 'fleet_metric_card.dart';

/// Audit §5 (O05/O30): the fleet metrics row, extracted from
/// [OwnerFleetView] so the view stays under the 250-line cap —
/// total / available / on-rent counts as [FleetMetricCard]s.
class FleetMetricsRow extends StatelessWidget {
  final int totalCount;
  final int availableCount;
  final int onRentCount;

  const FleetMetricsRow({
    super.key,
    required this.totalCount,
    required this.availableCount,
    required this.onRentCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          FleetMetricCard(
              label: l10n.fleetTotalFleet,
              value: l10n.fleetTotalCars(totalCount),
              icon: Icons.directions_car_rounded,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          FleetMetricCard(
              label: l10n.available,
              value: l10n.fleetAvailableReady(availableCount),
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.accentSuccess),
          const SizedBox(width: 8),
          // Audit §4: the On-Rent value is small text, so it uses the
          // brightness-aware orange TEXT token in both modes (light
          // #C2410C 5.18:1, dark #FB923C 7.92:1) — never the #F95700
          // fill as text.
          FleetMetricCard(
              label: l10n.fleetOnRent,
              value: l10n.fleetOnRentActive(onRentCount),
              icon: Icons.key_rounded,
              color: AppColors.orangeTextFor(
                  Theme.of(context).brightness)),
        ],
      ),
    );
  }
}
