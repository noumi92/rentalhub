import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'manual_booking_package_selector.dart';

/// The vehicle, package and deposit section of the walk-in booking
/// wizard. Extracted from [OwnerManualBookingView] so the view stays
/// under the 250-line cap.
class ManualBookingVehicleSection extends StatelessWidget {
  const ManualBookingVehicleSection({
    super.key,
    required this.isLoadingVehicles,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
    required this.selectedPackage,
    required this.onPackageChanged,
    required this.isWithDriver,
    required this.onDriverModeChanged,
    required this.depositController,
  });

  final bool isLoadingVehicles;
  final List<VehicleEntity> vehicles;
  final VehicleEntity? selectedVehicle;
  final ValueChanged<VehicleEntity?> onVehicleChanged;
  final VehiclePackageEntity? selectedPackage;
  final ValueChanged<VehiclePackageEntity?> onPackageChanged;
  final bool isWithDriver;
  final ValueChanged<bool> onDriverModeChanged;
  final TextEditingController depositController;

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (isLoadingVehicles)
          const Center(child: CircularProgressIndicator())
        else
          ManualBookingVehicleDropdown(
            vehicles: vehicles,
            selectedVehicle: selectedVehicle,
            onChanged: onVehicleChanged,
          ),
        const SizedBox(height: 12),
        ManualBookingPackageSelector(
          vehicle: selectedVehicle,
          selectedPackage: selectedPackage,
          onPackageChanged: onPackageChanged,
          isWithDriver: isWithDriver,
          onDriverModeChanged: onDriverModeChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: depositController,
          keyboardType: TextInputType.number,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: l10n.manualBookingDepositLabel,
            prefixIcon: const Icon(Icons.lock_clock_rounded,
                size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
