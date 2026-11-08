import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/custom_curved_header.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../constants/owner_vehicle_constants.dart';
import 'vehicle_photos_step_widget.dart';
import 'vehicle_rates_step_widget.dart';
import 'vehicle_review_step_widget.dart';
import 'vehicle_specs_step_widget.dart';

/// The header of the add-vehicle wizard (curved header + step counter),
/// extracted from [OwnerAddVehicleView] so the view stays under the
/// 250-line cap (rulebook D19).
class AddVehicleHeader extends StatelessWidget {
  const AddVehicleHeader({
    super.key,
    required this.currentStep,
    required this.onBack,
  });

  final int currentStep;
  final VoidCallback onBack;

  String _title(AppLocalizations l10n) => {
        1: l10n.addVehicleStep1Title,
        2: l10n.addVehicleStep2Title,
        3: l10n.addVehicleStep3Title,
      }[currentStep] ?? l10n.addVehicleStep4Title;

  String _subtitle(AppLocalizations l10n) => {
        1: l10n.addVehicleStep1Subtitle,
        2: l10n.addVehicleStep2Subtitle,
        3: l10n.addVehicleStep3Subtitle,
      }[currentStep] ?? l10n.addVehicleStep4Subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CustomCurvedHeader(
      variant: CustomCurvedHeaderVariant.compact,
      leadingWidget: IconButton(
        tooltip: l10n.back,
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: onBack,
      ),
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title(l10n),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  )),
          const SizedBox(height: 2),
          Text(_subtitle(l10n),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryContainer,
                  )),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12)),
          child: Text(l10n.addVehicleStepCounter(currentStep),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
        ),
      ],
    );
  }
}

/// The bottom action bar of the add-vehicle wizard.
class AddVehicleBottomBar extends StatelessWidget {
  const AddVehicleBottomBar({
    super.key,
    required this.currentStep,
    required this.onPressed,
  });

  final int currentStep;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          boxShadow: [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 8, offset: Offset(0, -3))
          ]),
      child: DebouncedButton(
        text: currentStep == 4 ? l10n.addVehicleConfirmPublish : l10n.addVehicleNextStep,
        icon: currentStep == 4
            ? Icons.check_circle_rounded
            : Icons.arrow_forward_rounded,
        onPressed: () async => onPressed(),
      ),
    );
  }
}

/// The four steps of the add-vehicle wizard, extracted from
/// [OwnerAddVehicleView] so the view stays under the 250-line cap
/// (rulebook D19). Each step is a thin forwarder: the view passes its
/// form state down as values and callbacks.
class AddVehicleSpecsStep extends StatelessWidget {
  const AddVehicleSpecsStep({
    super.key,
    required this.selectedMake,
    required this.onMakeChanged,
    required this.selectedModel,
    required this.onModelChanged,
    required this.selectedYear,
    required this.onYearChanged,
    required this.color,
    required this.onColorChanged,
    required this.category,
    required this.onCategoryChanged,
    required this.plateController,
    required this.onPlateChanged,
    required this.isAutomatic,
    required this.onTransmissionChanged,
    required this.fuelType,
    required this.onFuelTypeChanged,
    required this.seats,
    required this.onSeatsChanged,
    required this.hasAc,
    required this.onAcChanged,
    required this.selectedFeatures,
    required this.onFeatureToggled,
  });

  final String selectedMake;
  final ValueChanged<String> onMakeChanged;
  final String selectedModel;
  final ValueChanged<String> onModelChanged;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  final String color;
  final ValueChanged<String> onColorChanged;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final TextEditingController plateController;
  final VoidCallback onPlateChanged;
  final bool isAutomatic;
  final ValueChanged<bool> onTransmissionChanged;
  final String fuelType;
  final ValueChanged<String> onFuelTypeChanged;
  final int seats;
  final ValueChanged<int> onSeatsChanged;
  final bool hasAc;
  final ValueChanged<bool> onAcChanged;
  final Set<String> selectedFeatures;
  final ValueChanged<String> onFeatureToggled;

  @override
  Widget build(BuildContext context) {
    return VehicleSpecsStepWidget(
      selectedMake: selectedMake,
      onMakeChanged: onMakeChanged,
      makes: OwnerVehicleConstants.makes,
      selectedModel: selectedModel,
      onModelChanged: onModelChanged,
      selectedYear: selectedYear,
      onYearChanged: onYearChanged,
      color: color,
      onColorChanged: onColorChanged,
      category: category,
      onCategoryChanged: onCategoryChanged,
      categories: OwnerVehicleConstants.categories,
      plateController: plateController,
      onPlateChanged: onPlateChanged,
      isAutomatic: isAutomatic,
      onTransmissionChanged: onTransmissionChanged,
      fuelType: fuelType,
      onFuelTypeChanged: onFuelTypeChanged,
      seats: seats,
      onSeatsChanged: onSeatsChanged,
      hasAc: hasAc,
      onAcChanged: onAcChanged,
      selectedFeatures: selectedFeatures,
      onFeatureToggled: onFeatureToggled,
    );
  }
}

class AddVehiclePhotosStep extends StatelessWidget {
  const AddVehiclePhotosStep({
    super.key,
    required this.photoFrontFile,
    required this.onPickFront,
    required this.onRemoveFront,
    required this.photoBackFile,
    required this.onPickBack,
    required this.onRemoveBack,
    required this.photoSideFile,
    required this.onPickSide,
    required this.onRemoveSide,
    required this.photoInteriorFile,
    required this.onPickInterior,
    required this.onRemoveInterior,
    required this.regBookFile,
    required this.onPickRegBook,
    required this.onRemoveRegBook,
    required this.tokenTaxFile,
    required this.onPickTokenTax,
    required this.onRemoveTokenTax,
    required this.insuranceFile,
    required this.onPickInsurance,
    required this.onRemoveInsurance,
  });

  final XFile? photoFrontFile;
  final VoidCallback onPickFront;
  final VoidCallback onRemoveFront;
  final XFile? photoBackFile;
  final VoidCallback onPickBack;
  final VoidCallback onRemoveBack;
  final XFile? photoSideFile;
  final VoidCallback onPickSide;
  final VoidCallback onRemoveSide;
  final XFile? photoInteriorFile;
  final VoidCallback onPickInterior;
  final VoidCallback onRemoveInterior;
  final XFile? regBookFile;
  final VoidCallback onPickRegBook;
  final VoidCallback onRemoveRegBook;
  final XFile? tokenTaxFile;
  final VoidCallback onPickTokenTax;
  final VoidCallback onRemoveTokenTax;
  final XFile? insuranceFile;
  final VoidCallback onPickInsurance;
  final VoidCallback onRemoveInsurance;

  @override
  Widget build(BuildContext context) {
    return VehiclePhotosStepWidget(
      photoFrontFile: photoFrontFile,
      onPickFront: onPickFront,
      onRemoveFront: onRemoveFront,
      photoBackFile: photoBackFile,
      onPickBack: onPickBack,
      onRemoveBack: onRemoveBack,
      photoSideFile: photoSideFile,
      onPickSide: onPickSide,
      onRemoveSide: onRemoveSide,
      photoInteriorFile: photoInteriorFile,
      onPickInterior: onPickInterior,
      onRemoveInterior: onRemoveInterior,
      regBookFile: regBookFile,
      onPickRegBook: onPickRegBook,
      onRemoveRegBook: onRemoveRegBook,
      tokenTaxFile: tokenTaxFile,
      onPickTokenTax: onPickTokenTax,
      onRemoveTokenTax: onRemoveTokenTax,
      insuranceFile: insuranceFile,
      onPickInsurance: onPickInsurance,
      onRemoveInsurance: onRemoveInsurance,
    );
  }
}

class AddVehicleRatesStep extends StatelessWidget {
  const AddVehicleRatesStep({
    super.key,
    required this.enable1Hour,
    required this.onToggle1Hour,
    required this.rate1HourController,
    required this.enable3Hours,
    required this.onToggle3Hours,
    required this.rate3HoursController,
    required this.enable6Hours,
    required this.onToggle6Hours,
    required this.rate6HoursController,
    required this.enable24Hours,
    required this.onToggle24Hours,
    required this.rate24HoursController,
    required this.enableWeekly,
    required this.onToggleWeekly,
    required this.rateWeeklyController,
    required this.supportSelfDrive,
    required this.onToggleSelfDrive,
    required this.supportWithDriver,
    required this.onToggleWithDriver,
    required this.driverAllowanceController,
    required this.securityDepositController,
    required this.advanceDepositController,
    required this.extraHourChargeController,
    required this.fuelPolicy,
    required this.onFuelPolicyChanged,
  });

  final bool enable1Hour;
  final ValueChanged<bool> onToggle1Hour;
  final TextEditingController rate1HourController;
  final bool enable3Hours;
  final ValueChanged<bool> onToggle3Hours;
  final TextEditingController rate3HoursController;
  final bool enable6Hours;
  final ValueChanged<bool> onToggle6Hours;
  final TextEditingController rate6HoursController;
  final bool enable24Hours;
  final ValueChanged<bool> onToggle24Hours;
  final TextEditingController rate24HoursController;
  final bool enableWeekly;
  final ValueChanged<bool> onToggleWeekly;
  final TextEditingController rateWeeklyController;
  final bool supportSelfDrive;
  final ValueChanged<bool> onToggleSelfDrive;
  final bool supportWithDriver;
  final ValueChanged<bool> onToggleWithDriver;
  final TextEditingController driverAllowanceController;
  final TextEditingController securityDepositController;
  final TextEditingController advanceDepositController;
  final TextEditingController extraHourChargeController;
  final String fuelPolicy;
  final ValueChanged<String> onFuelPolicyChanged;

  @override
  Widget build(BuildContext context) {
    return VehicleRatesStepWidget(
      enable1Hour: enable1Hour,
      onToggle1Hour: onToggle1Hour,
      rate1HourController: rate1HourController,
      enable3Hours: enable3Hours,
      onToggle3Hours: onToggle3Hours,
      rate3HoursController: rate3HoursController,
      enable6Hours: enable6Hours,
      onToggle6Hours: onToggle6Hours,
      rate6HoursController: rate6HoursController,
      enable24Hours: enable24Hours,
      onToggle24Hours: onToggle24Hours,
      rate24HoursController: rate24HoursController,
      enableWeekly: enableWeekly,
      onToggleWeekly: onToggleWeekly,
      rateWeeklyController: rateWeeklyController,
      supportSelfDrive: supportSelfDrive,
      onToggleSelfDrive: onToggleSelfDrive,
      supportWithDriver: supportWithDriver,
      onToggleWithDriver: onToggleWithDriver,
      driverAllowanceController: driverAllowanceController,
      securityDepositController: securityDepositController,
      advanceDepositController: advanceDepositController,
      extraHourChargeController: extraHourChargeController,
      fuelPolicy: fuelPolicy,
      onFuelPolicyChanged: onFuelPolicyChanged,
      fuelPolicies: OwnerVehicleConstants.fuelPolicies,
    );
  }
}

class AddVehicleReviewStep extends StatelessWidget {
  const AddVehicleReviewStep({
    super.key,
    required this.photoFrontFile,
    required this.selectedMake,
    required this.selectedModel,
    required this.category,
    required this.selectedYear,
    required this.color,
    required this.plateNumber,
    required this.isAutomatic,
    required this.fuelType,
    required this.seats,
    required this.dailyRate,
    required this.driverAllowance,
    required this.supportSelfDrive,
    required this.supportWithDriver,
    required this.deposit,
    required this.advance,
    required this.extraHour,
    required this.fuelPolicy,
  });

  final XFile? photoFrontFile;
  final String selectedMake;
  final String selectedModel;
  final String category;
  final int selectedYear;
  final String color;
  final String plateNumber;
  final bool isAutomatic;
  final String fuelType;
  final int seats;
  final int dailyRate;
  final int driverAllowance;
  final bool supportSelfDrive;
  final bool supportWithDriver;
  final int deposit;
  final int advance;
  final int extraHour;
  final String fuelPolicy;

  @override
  Widget build(BuildContext context) {
    return VehicleReviewStepWidget(
      photoFrontFile: photoFrontFile,
      selectedMake: selectedMake,
      selectedModel: selectedModel,
      category: category,
      selectedYear: selectedYear,
      color: color,
      plateNumber: plateNumber,
      isAutomatic: isAutomatic,
      fuelType: fuelType,
      seats: seats,
      dailyRate: dailyRate,
      driverAllowance: driverAllowance,
      supportSelfDrive: supportSelfDrive,
      supportWithDriver: supportWithDriver,
      deposit: deposit,
      advance: advance,
      extraHour: extraHour,
      fuelPolicy: fuelPolicy,
    );
  }
}
