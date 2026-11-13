import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../fleet/presentation/cubit/fleet_state.dart';
import 'fleet_vehicle_card.dart';

/// The body of the fleet list: loading, error, empty and populated states.
/// Extracted from [OwnerFleetView] so the view stays under the 250-line cap.
/// Header rework (2026-11-09): the card carries the whole header on
/// the photo and exactly one icon-button row below it — Rates (09b
/// editor), Out-of-city rules (010b) and Edit (edit-details route,
/// only when [onEditDetails] is provided; wired by the fleet view).
class FleetBody extends StatelessWidget {
  const FleetBody({
    super.key,
    required this.state,
    required this.fleet,
    required this.filtered,
    required this.onAddVehicle,
    required this.onRetry,
    required this.onEditRates,
    required this.onOutCityRules,
    required this.onTapVehicle,
    this.onEditDetails,
    this.rentedUntilFor,
  });

  final FleetState state;
  final List<VehicleEntity> fleet;
  final List<VehicleEntity> filtered;
  final VoidCallback onAddVehicle;
  final VoidCallback onRetry;
  final void Function(VehicleEntity vehicle) onEditRates;
  final void Function(VehicleEntity vehicle) onOutCityRules;
  final void Function(VehicleEntity vehicle) onTapVehicle;

  /// Opens the edit-details route for the vehicle; null hides the
  /// card's Edit icon button. The fleet view wires this.
  final void Function(VehicleEntity vehicle)? onEditDetails;

  /// RQ-F10: the active booking's return date per vehicle (the fleet
  /// view loads it from the shop bookings); null renders no line.
  final DateTime? Function(VehicleEntity vehicle)? rentedUntilFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state is FleetLoading) {
      // E2: shared loading state.
      return AppLoadingState(message: l10n.fleetLoading);
    }
    if (state is FleetError) {
      // E2: shared error state with retry.
      return AppErrorState(
        message: l10n.fleetLoadError((state as FleetError).message),
        onRetry: onRetry,
      );
    }
    if (filtered.isEmpty) {
      // E2: shared empty state; the action only adds a vehicle when
      // the fleet itself is empty — a filter with no matches has no
      // sensible "add" action.
      return AppEmptyState(
        title: fleet.isEmpty
            ? l10n.fleetEmptyTitle
            : l10n.fleetEmptyFilterTitle,
        message: fleet.isEmpty
            ? l10n.fleetEmptyMessage
            : l10n.fleetEmptyFilterMessage,
        icon: Icons.no_crash_rounded,
        actionLabel: fleet.isEmpty ? l10n.fleetAddVehicleNow : null,
        onAction: fleet.isEmpty ? onAddVehicle : null,
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final v = filtered[index];
        return FleetVehicleCard(
          vehicle: v,
          onEditRates: () => onEditRates(v),
          onOutCityRules: () => onOutCityRules(v),
          onEditDetails: onEditDetails == null ? null : () => onEditDetails!(v),
          onTap: () => onTapVehicle(v),
          rentedUntil: rentedUntilFor?.call(v),
        );
      },
    );
  }
}
