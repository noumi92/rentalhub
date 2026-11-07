import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/update_vehicle_pricing_usecase.dart';
import '../constants/owner_vehicle_constants.dart';
import '../widgets/fleet/pricing_chrome.dart';
import '../widgets/fleet/pricing_drive_mode_card.dart';
import '../widgets/fleet/pricing_package_list.dart';
import '../widgets/fleet/pricing_policy_fields.dart';

/// Phase B (B2): the rate matrix now edits the vehicle's real packages
/// (price + on/off toggle per package, incl. 12h and Weekly), the
/// out-of-city rate, the with-driver surcharge, security deposit,
/// advance, extra-hour charge and fuel policy — and it actually saves
/// the drive-mode switches too (they used to be loaded but never
/// persisted). Everything saves in one write via
/// [UpdateVehiclePricingUseCase]; the legacy `rates` fields are kept
/// in sync so existing readers keep working.
class OwnerRateMatrixView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onRatesSaved;
  final VoidCallback? onBack;

  const OwnerRateMatrixView({
    super.key,
    required this.vehicle,
    this.onRatesSaved,
    this.onBack,
  });

  @override
  State<OwnerRateMatrixView> createState() => _OwnerRateMatrixViewState();
}

class _OwnerRateMatrixViewState extends State<OwnerRateMatrixView> {
  late List<VehiclePackageEntity> _packages;
  final Map<String, TextEditingController> _priceControllers = {};
  late TextEditingController _outOfCityController;
  late TextEditingController _surchargeController;
  late TextEditingController _depositController;
  late TextEditingController _advanceController;
  late TextEditingController _extraHourController;
  late TextEditingController _extraKmController;
  late TextEditingController _outOfCityKmController;

  late bool _isSelfDrive;
  late bool _isWithDriver;
  late String _fuelPolicy;
  bool _isSaving = false;

  int _priceOf(String label) {
    final p = _packages.firstWhere((e) => e.label == label,
        orElse: () => _packages.first);
    return int.tryParse(_priceControllers[label]?.text.trim() ?? '') ??
        p.pricePkr;
  }

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _packages = List.of(v.effectivePackages);
    for (final p in _packages) {
      _priceControllers[p.label] =
          TextEditingController(text: p.pricePkr.toString());
    }
    _outOfCityController = TextEditingController(
        text: (v.rates.outOfCityDaily ?? (v.rates.daily24 * 1.3).round())
            .toString());
    _surchargeController = TextEditingController(
        text: (v.withDriverSurchargePkr ?? 2000).toString());
    _depositController = TextEditingController(
        text: (v.securityDepositPkr ?? 25000).toString());
    _advanceController = TextEditingController(
        text: (v.advanceRequiredPkr ?? 2000).toString());
    _extraHourController = TextEditingController(
        text: (v.extraHourPkr ?? 600).toString());
    _extraKmController = TextEditingController(
        text: (v.extraKmPkr ?? 100).toString());
    _outOfCityKmController = TextEditingController(
        text: (v.outOfCityKmPerDay ?? 350).toString());
    _isSelfDrive = v.isSelfDriveAvailable;
    _isWithDriver = v.isWithDriverAvailable;
    _fuelPolicy = v.fuelPolicy ?? 'Same to Same';
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    _outOfCityController.dispose();
    _surchargeController.dispose();
    _depositController.dispose();
    _advanceController.dispose();
    _extraHourController.dispose();
    _extraKmController.dispose();
    _outOfCityKmController.dispose();
    super.dispose();
  }

  Future<void> _saveRates() async {
    setState(() => _isSaving = true);
    try {
      final updatedPackages = _packages
          .map((p) => p.copyWith(pricePkr: _priceOf(p.label)))
          .toList();
      final updated = widget.vehicle.copyWith(
        packages: updatedPackages,
        rates: VehicleRatesEntity(
          hourly1: _priceOf('1h'),
          hourly3: _priceOf('3h'),
          hourly6: _priceOf('6h'),
          daily24: _priceOf('24h'),
          outOfCityDaily:
              int.tryParse(_outOfCityController.text.trim()) ?? 10500,
        ),
        weeklyRate: _priceOf('Weekly'),
        isSelfDriveAvailable: _isSelfDrive,
        isWithDriverAvailable: _isWithDriver,
        withDriverSurchargePkr:
            int.tryParse(_surchargeController.text.trim()) ?? 2000,
        securityDepositPkr:
            int.tryParse(_depositController.text.trim()) ?? 25000,
        advanceRequiredPkr:
            int.tryParse(_advanceController.text.trim()) ?? 2000,
        extraHourPkr:
            int.tryParse(_extraHourController.text.trim()) ?? 600,
        extraKmPkr: int.tryParse(_extraKmController.text.trim()) ?? 100,
        outOfCityKmPerDay:
            int.tryParse(_outOfCityKmController.text.trim()) ?? 350,
        fuelPolicy: _fuelPolicy,
      );

      await sl<UpdateVehiclePricingUseCase>()(
        vehicleId: widget.vehicle.vehicleId,
        vehicle: updated,
      );

      if (mounted) {
        AppFeedback.showSuccess(
            context, 'Pricing matrix updated in showroom!');
        widget.onRatesSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Failed to update rates: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PricingHeader(vehicle: v, onBack: widget.onBack),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drive Mode Availability',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    PricingDriveModeCard(
                      isSelfDrive: _isSelfDrive,
                      onSelfDriveChanged: (val) =>
                          setState(() => _isSelfDrive = val),
                      isWithDriver: _isWithDriver,
                      onWithDriverChanged: (val) =>
                          setState(() => _isWithDriver = val),
                    ),
                    const SizedBox(height: 18),
                    Text('Rental Packages',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(
                        'Switch a package off to hide it from customers.',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    PricingPackageList(
                      packages: _packages,
                      onToggle: (label, val) => setState(() {
                        final i = _packages
                            .indexWhere((p) => p.label == label);
                        if (i != -1) {
                          _packages[i] =
                              _packages[i].copyWith(enabled: val);
                        }
                      }),
                      priceController: (label) => _priceControllers[label]!,
                    ),
                    const SizedBox(height: 18),
                    Text('Pricing Policy',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    PricingPolicyFields(
                      outOfCityController: _outOfCityController,
                      surchargeController: _surchargeController,
                      depositController: _depositController,
                      advanceController: _advanceController,
                      extraHourController: _extraHourController,
                      extraKmController: _extraKmController,
                      outOfCityKmController: _outOfCityKmController,
                      fuelPolicy: _fuelPolicy,
                      onFuelPolicyChanged: (f) =>
                          setState(() => _fuelPolicy = f),
                      fuelPolicies: OwnerVehicleConstants.fuelPolicies,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            PricingSaveBar(isSaving: _isSaving, onPressed: _saveRates),
          ],
        ),
      ),
    );
  }
}
