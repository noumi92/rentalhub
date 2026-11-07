import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// The vehicle dropdown of the walk-in booking wizard. Extracted from
/// [OwnerManualBookingView] so the view stays under the 250-line cap.
class ManualBookingVehicleDropdown extends StatelessWidget {
  const ManualBookingVehicleDropdown({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onChanged,
  });

  final List<VehicleEntity> vehicles;
  final VehicleEntity? selectedVehicle;
  final ValueChanged<VehicleEntity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VehicleEntity>(
          isExpanded: true,
          value: selectedVehicle,
          hint: const Text('Select Showroom Vehicle'),
          items: vehicles.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text(
                  '${v.make} ${v.model} (${v.year}) - ${v.plateNumber}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// The package selector of the walk-in booking wizard: one chip per
/// enabled package of the chosen vehicle, with the computed total
/// (package price + with-driver surcharge) shown below. Extracted from
/// [OwnerManualBookingView] so the view stays under the 250-line cap.
/// Phase B (B2): the counter total comes from the vehicle's package,
/// not from a typed number.
class ManualBookingPackageSelector extends StatelessWidget {
  const ManualBookingPackageSelector({
    super.key,
    required this.vehicle,
    required this.selectedPackage,
    required this.onPackageChanged,
    required this.isWithDriver,
    required this.onDriverModeChanged,
  });

  final VehicleEntity? vehicle;
  final VehiclePackageEntity? selectedPackage;
  final ValueChanged<VehiclePackageEntity> onPackageChanged;
  final bool isWithDriver;
  final ValueChanged<bool> onDriverModeChanged;

  /// The counter total for a package, shared with the view that creates
  /// the booking so the displayed total and the booked total never drift.
  static int totalFor({
    required VehicleEntity? vehicle,
    required VehiclePackageEntity? package,
    required bool isWithDriver,
  }) {
    if (vehicle == null || package == null) return 0;
    if (!isWithDriver) return package.pricePkr;
    final perDay = vehicle.withDriverSurchargePkr ?? 0;
    final surcharge = package.hours >= 24
        ? perDay * (package.hours ~/ 24)
        : (perDay * package.hours / 24).round();
    return package.pricePkr + surcharge;
  }

  /// Phase B (D2): the return time follows the chosen package — a
  /// 6-hour package returns in 6 hours, a weekly one in 7 days.
  static DateTime returnTimeFor({
    required DateTime pickup,
    required VehiclePackageEntity package,
  }) {
    return pickup.add(Duration(hours: package.hours));
  }

  int get _total => totalFor(
        vehicle: vehicle,
        package: selectedPackage,
        isWithDriver: isWithDriver,
      );

  @override
  Widget build(BuildContext context) {
    final vehicle = this.vehicle;
    if (vehicle == null) {
      return Text('Select a vehicle first to see its packages.',
          style: Theme.of(context).textTheme.bodySmall);
    }
    final packages = vehicle.enabledPackages;
    if (packages.isEmpty) {
      return Text('This vehicle has no packages enabled.',
          style: Theme.of(context).textTheme.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packages.map((p) {
            final selected = selectedPackage?.label == p.label;
            return ChoiceChip(
              label: Text('${p.label} • Rs. ${p.pricePkr}'),
              selected: selected,
              selectedColor: AppColors.secondary,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.primary,
              ),
              onSelected: (_) => onPackageChanged(p),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('With Driver',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            Switch(
              value: isWithDriver,
              activeThumbColor: AppColors.secondary,
              onChanged: onDriverModeChanged,
            ),
            const SizedBox(width: 8),
            Text('Total: Rs. $_total',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                )),
          ],
        ),
      ],
    );
  }
}
