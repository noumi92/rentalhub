import 'package:flutter/material.dart';

import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'guarantor_picker.dart';
import 'manual_booking_customer_fields.dart';
import 'manual_booking_package_selector.dart';
import 'manual_booking_schedule_section.dart';
import 'manual_booking_vehicle_section.dart';

/// The scrollable form of the manual booking wizard — customer,
/// guarantor, vehicle + package, schedule. Extracted from
/// [OwnerManualBookingView] so the view stays under the 250-line cap.
class ManualBookingFormBody extends StatelessWidget {
  const ManualBookingFormBody({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.cnicController,
    required this.onGuarantorChanged,
    required this.vehiclesError,
    required this.onRetryLoad,
    required this.isLoadingVehicles,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
    required this.selectedPackage,
    required this.onPackageChanged,
    required this.isWithDriver,
    required this.onDriverModeChanged,
    required this.depositController,
    required this.isOutOfCity,
    required this.pickupTime,
    required this.returnTime,
    required this.onPickupChanged,
    required this.onReturnChanged,
    required this.onTripTypeChanged,
    required this.isChecking,
    required this.onNext,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cnicController;
  final ValueChanged<GuarantorSelection?> onGuarantorChanged;
  final String? vehiclesError;
  final VoidCallback onRetryLoad;
  final bool isLoadingVehicles;
  final List<VehicleEntity> vehicles;
  final VehicleEntity? selectedVehicle;
  final ValueChanged<VehicleEntity?> onVehicleChanged;
  final VehiclePackageEntity? selectedPackage;
  final ValueChanged<VehiclePackageEntity?> onPackageChanged;
  final bool isWithDriver;
  final ValueChanged<bool> onDriverModeChanged;
  final TextEditingController depositController;
  final bool isOutOfCity;
  final DateTime pickupTime;
  final DateTime returnTime;
  final ValueChanged<DateTime> onPickupChanged;
  final ValueChanged<DateTime> onReturnChanged;
  final ValueChanged<bool> onTripTypeChanged;
  final bool isChecking;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, l10n.manualBookingCustomerSection),
          ManualBookingCustomerFields(
              nameController: nameController,
              phoneController: phoneController,
              cnicController: cnicController),
          const SizedBox(height: 18),
          _sectionHeader(context, l10n.manualBookingGuarantorSection),
          GuarantorPicker(onChanged: onGuarantorChanged),
          const SizedBox(height: 18),
          _sectionHeader(context, l10n.manualBookingVehicleSection),
          if (vehiclesError != null)
            ManualBookingLoadErrorCard(
                message: l10n.fleetLoadError(vehiclesError!),
                onRetry: onRetryLoad)
          else
            ManualBookingVehicleSection(
              isLoadingVehicles: isLoadingVehicles,
              vehicles: vehicles,
              selectedVehicle: selectedVehicle,
              onVehicleChanged: onVehicleChanged,
              selectedPackage: selectedPackage,
              onPackageChanged: onPackageChanged,
              isWithDriver: isWithDriver,
              onDriverModeChanged: onDriverModeChanged,
              depositController: depositController,
              isOutOfCity: isOutOfCity,
              pickup: pickupTime,
              returnTime: returnTime,
            ),
          const SizedBox(height: 18),
          ManualBookingScheduleSection(
            pickupTime: pickupTime,
            returnTime: returnTime,
            onPickupChanged: onPickupChanged,
            onReturnChanged: onReturnChanged,
            isOutOfCity: isOutOfCity,
            onTripTypeChanged: onTripTypeChanged,
          ),
          const SizedBox(height: 24),
          DebouncedButton(
              text: isChecking
                  ? l10n.manualBookingCreating
                  : l10n.manualBookingNext,
              icon: Icons.arrow_forward_rounded,
              isLoading: isChecking,
              onPressed: onNext),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}
