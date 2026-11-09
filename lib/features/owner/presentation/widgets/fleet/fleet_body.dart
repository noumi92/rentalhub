import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../fleet/presentation/cubit/fleet_state.dart';
import 'fleet_vehicle_card.dart';

/// The body of the fleet list: loading, error, empty and populated states.
/// Extracted from [OwnerFleetView] so the view stays under the 250-line cap.
class FleetBody extends StatelessWidget {
  const FleetBody({
    super.key,
    required this.state,
    required this.fleet,
    required this.filtered,
    required this.onAddVehicle,
    required this.onRetry,
    required this.onToggleAvailability,
    required this.onEditRates,
    required this.onViewCalendar,
    required this.onTapVehicle,
    this.rentedUntil = const {},
    this.onEditRent,
    this.onUpdatePrice,
  });

  final FleetState state;
  final List<VehicleEntity> fleet;
  final List<VehicleEntity> filtered;
  final VoidCallback onAddVehicle;
  final VoidCallback onRetry;
  final void Function(VehicleEntity vehicle, bool available)
      onToggleAvailability;
  final void Function(VehicleEntity vehicle) onEditRates;
  final void Function(VehicleEntity vehicle) onViewCalendar;
  final void Function(VehicleEntity vehicle) onTapVehicle;

  /// Audit §5 (O05/O30): active-booking return dates by vehicle id,
  /// plus the literal "Edit Rent" / "Update Price" actions.
  final Map<String, DateTime> rentedUntil;
  final void Function(VehicleEntity vehicle)? onEditRent;
  final void Function(VehicleEntity vehicle)? onUpdatePrice;

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
          onToggleAvailability: (val) => onToggleAvailability(v, val),
          onEditRates: () => onEditRates(v),
          onViewCalendar: () => onViewCalendar(v),
          onTap: () => onTapVehicle(v),
          rentedUntil: rentedUntil[v.vehicleId],
          onEditRent: onEditRent == null ? null : () => onEditRent!(v),
          onUpdatePrice: onUpdatePrice == null ? null : () => onUpdatePrice!(v),
        );
      },
    );
  }
}
