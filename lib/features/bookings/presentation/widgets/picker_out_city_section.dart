import 'package:flutter/material.dart';

import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'trip_type_section.dart';

/// RentPackagePickerView's out-of-city block, extracted so the picker
/// view stays under the 250-line cap (consolidation 2026-11-15).
/// Thin pass-through: all state and callbacks live in the picker.
class PickerOutCitySection extends StatelessWidget {
  const PickerOutCitySection({
    super.key,
    required this.vehicle,
    required this.isOutOfCity,
    required this.onChanged,
    required this.routes,
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.pickup,
    required this.returnTime,
    required this.kmPerDay,
  });

  final VehicleEntity vehicle;
  final bool isOutOfCity;
  final ValueChanged<bool> onChanged;
  final List<FixedRouteEntity> routes;
  final FixedRouteEntity? selectedRoute;
  final ValueChanged<FixedRouteEntity?> onRouteSelected;
  final DateTime pickup;
  final DateTime returnTime;
  final int kmPerDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        TripTypeSection(
          isOutOfCity: isOutOfCity,
          onChanged: onChanged,
          fixedRoutes: routes,
          selectedRoute: selectedRoute,
          onRouteSelected: onRouteSelected,
          // CU-m17: the section states the out-of-city price basis
          // from the vehicle's own fields.
          outCityMode: vehicle.outCityMode,
          outCityPerKmPkr: vehicle.outCityPerKmPkr,
          outCityDailyPkr:
              vehicle.rates.outOfCityDaily ?? vehicle.rates.daily24,
          // PW-13: the picked dates + the tier's km/day, so the
          // per-km estimate ("≈ Rs. X for N days × Y km/day") renders
          // live. The tier carries perKmKmPerDay in per-km mode; the
          // vehicle's stored allowance (default 300) is the fallback
          // the tier builder itself uses.
          pickup: pickup,
          returnTime: returnTime,
          kmPerDay: kmPerDay,
        ),
      ],
    );
  }
}
