import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    if (state is FleetLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state is FleetError) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 54, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Could not load your fleet: ${(state as FleetError).message}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.no_crash_rounded,
                  size: 54, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                fleet.isEmpty
                    ? 'No vehicles yet — add your first car'
                    : 'No vehicles found in this filter',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onAddVehicle,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Vehicle Now'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
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
        );
      },
    );
  }
}
