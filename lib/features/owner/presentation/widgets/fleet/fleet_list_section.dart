import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../fleet/presentation/cubit/fleet_state.dart';
import 'fleet_body.dart';
import 'fleet_vehicle_card.dart';

/// The fleet list section of `OwnerFleetView`: D3 medium+ shows two
/// columns, compact keeps `FleetBody`. Extracted from the view so it
/// stays under the 250-line cap (rulebook §2.2).
///
/// One fleet card serves both layouts (photo header on top, exactly
/// one action row below: Rates, Out-of-city rules, Edit when wired),
/// and RQ-F10 threads the active booking's return date onto On-Rent
/// cards via [rentedUntilFor].
class FleetListSection extends StatelessWidget {
  const FleetListSection({
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
  /// card's Edit icon button.
  final void Function(VehicleEntity vehicle)? onEditDetails;

  /// RQ-F10: the active booking's return date per vehicle; null
  /// renders no line on the card.
  final DateTime? Function(VehicleEntity vehicle)? rentedUntilFor;

  /// D3: one fleet card for both the compact list and the two-column
  /// grid. Simplified card (2026-11-09): only Rates (09b) and
  /// Out-of-city rules (010b) — no availability toggle, calendar,
  /// rent-edit or price-edit actions on the card.
  Widget _vehicleCard(VehicleEntity v) => FleetVehicleCard(
        vehicle: v,
        onTap: () => onTapVehicle(v),
        onEditRates: () => onEditRates(v),
        onOutCityRules: () => onOutCityRules(v),
        // Phone-test round 4 (Worker 3 owns the card): the Edit icon
        // opens the car-details editor, same route as the detail view.
        onEditDetails:
            onEditDetails == null ? null : () => onEditDetails!(v),
        // RQ-F10: the active booking's return date on On-Rent cards.
        rentedUntil: rentedUntilFor?.call(v),
      );

  @override
  Widget build(BuildContext context) {
    if (isMediumOrLarger(context) && filtered.isNotEmpty) {
      return twoColumnLayout(
        key: const Key('fleet-two-columns'),
        items: filtered,
        padding: const EdgeInsets.all(16),
        itemBuilder: _vehicleCard,
      );
    }
    return FleetBody(
      state: state,
      fleet: fleet,
      filtered: filtered,
      onAddVehicle: onAddVehicle,
      onRetry: onRetry,
      onEditRates: onEditRates,
      onOutCityRules: onOutCityRules,
      // Phone-test round 4 (Worker 3 owns FleetBody): the card's
      // Edit icon opens the car-details editor, same route as the
      // detail view.
      onEditDetails: onEditDetails,
      onTapVehicle: onTapVehicle,
      rentedUntilFor: rentedUntilFor,
    );
  }
}
