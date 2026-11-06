import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/media_picker_helper.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/add_vehicle_usecase.dart';
import '../services/vehicle_photo_upload_service.dart';
import '../widgets/add_vehicle/add_vehicle_step_content.dart';
import '../widgets/add_vehicle/add_vehicle_stepper_bar.dart';

/// Phase B (B1): builds a real [VehicleEntity] and saves it through
/// [AddVehicleUseCase] instead of returning a mock vehicle.
class OwnerAddVehicleView extends StatefulWidget {
  final ValueChanged<VehicleEntity>? onVehicleAdded;
  final String? shopId;
  const OwnerAddVehicleView({super.key, this.onVehicleAdded, this.shopId});

  @override
  State<OwnerAddVehicleView> createState() => _OwnerAddVehicleViewState();
}

class _OwnerAddVehicleViewState extends State<OwnerAddVehicleView> {
  int _currentStep = 1;

  // Step 1: Specs, Capacity, AC & Extra Features
  String _selectedMake = 'Toyota', _selectedModel = 'Corolla Altis Grande', _color = 'Super White', _category = 'Sedan', _fuelType = 'Petrol';
  int _selectedYear = 2023, _seats = 5;
  final _plateController = TextEditingController(text: 'LEA-23-4567');
  bool _isAutomatic = true, _hasAc = true;
  final Set<String> _selectedFeatures = {'ABS Brakes', 'Dual Airbags', 'Bluetooth Audio', 'Power Windows', 'GPS Tracking'};

  // Step 2: Photos (Camera + Gallery + Remove)
  XFile? _photoFrontFile, _photoBackFile, _photoSideFile, _photoInteriorFile;
  XFile? _regBookFile, _tokenTaxFile, _insuranceFile;

  // Step 3: Rates & Policies
  bool _enable1Hour = true, _enable3Hours = true, _enable6Hours = true, _enable24Hours = true, _enableWeekly = true;
  final _rate1HourController = TextEditingController(text: '1200'), _rate3HoursController = TextEditingController(text: '3000'), _rate6HoursController = TextEditingController(text: '5500'), _rate24HoursController = TextEditingController(text: '8500'), _rateWeeklyController = TextEditingController(text: '52000');
  bool _supportSelfDrive = true, _supportWithDriver = true;
  final _driverAllowanceController = TextEditingController(text: '2000'), _securityDepositController = TextEditingController(text: '25000'), _advanceDepositController = TextEditingController(text: '2000'), _extraHourChargeController = TextEditingController(text: '600');
  String _fuelPolicy = 'Same to Same';

  @override
  void dispose() {
    for (final c in [_plateController, _rate1HourController, _rate3HoursController, _rate6HoursController, _rate24HoursController, _rateWeeklyController, _driverAllowanceController, _securityDepositController, _advanceDepositController, _extraHourChargeController]) {
      c.dispose();
    }
    super.dispose();
  }

  void _chooseMedia(Function(XFile?) onSet, {bool hasExisting = false}) {
    MediaPickerHelper.showMediaSourceSheet(context: context, onImageSelected: (f) => setState(() => onSet(f)), hasExistingFile: hasExisting);
  }

  int _getInt(TextEditingController ctrl, int fallback) => int.tryParse(ctrl.text.trim()) ?? fallback;

  bool _validateStep() {
    if (_currentStep == 1) {
      if (_selectedModel.trim().isEmpty) return _stepErr('Please specify vehicle model variant.');
      if (_plateController.text.trim().isEmpty) return _stepErr('Registration plate number is required.');
    } else if (_currentStep == 3) {
      final r = PakistaniValidators.validateRentalRate(_rate24HoursController.text, label: 'Full Day Rate');
      if (r != null) return _stepErr(r);
      final d = PakistaniValidators.validateRentalRate(_securityDepositController.text, label: 'Security Deposit', allowZero: true);
      if (d != null) return _stepErr(d);
    }
    return true;
  }
  bool _stepErr(String msg) { AppFeedback.showError(context, msg); return false; }

  void _next() async {
    if (!_validateStep()) return;
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      return;
    }
    await _saveVehicle();
  }

  Future<void> _saveVehicle() async {
    final shopId = widget.shopId ?? currentShopId();
    final imageUrl = await VehiclePhotoUploadService.uploadFrontPhoto(
        shopId: shopId, photo: _photoFrontFile) ??
        _photoFrontFile?.path;
    final vehicle = VehicleEntity(
      vehicleId: 'v-${DateTime.now().millisecondsSinceEpoch}',
      shopId: shopId, make: _selectedMake, model: _selectedModel, year: _selectedYear,
      plateNumber: _plateController.text.trim().isEmpty ? 'LEA-23-4567' : _plateController.text.trim(),
      category: _category, transmission: _isAutomatic ? 'Automatic' : 'Manual',
      fuelType: _fuelType, seats: _seats,
      isSelfDriveAvailable: _supportSelfDrive, isWithDriverAvailable: _supportWithDriver,
      rates: VehicleRatesEntity(
        hourly1: _enable1Hour ? _getInt(_rate1HourController, 1200) : null,
        hourly3: _enable3Hours ? _getInt(_rate3HoursController, 3000) : null,
        hourly6: _enable6Hours ? _getInt(_rate6HoursController, 5500) : null,
        daily24: _getInt(_rate24HoursController, 8500)),
      imageUrl: imageUrl, color: _color, features: _selectedFeatures.toList(),
      weeklyRate: _enableWeekly ? _getInt(_rateWeeklyController, 52000) : null,
      securityDepositPkr: _getInt(_securityDepositController, 25000),
      advanceRequiredPkr: _getInt(_advanceDepositController, 2000),
      extraHourPkr: _getInt(_extraHourChargeController, 600),
      withDriverSurchargePkr: _getInt(_driverAllowanceController, 2000),
      fuelPolicy: _fuelPolicy,
    );
    try {
      await sl<AddVehicleUseCase>()(shopId: shopId, vehicle: vehicle);
    } catch (e) {
      // Freemium 3-car limit and other save failures surface here.
      if (mounted) _stepErr(e.toString());
      return;
    }
    if (!mounted) return;
    widget.onVehicleAdded?.call(vehicle);
    AppFeedback.showSuccess(context, '${vehicle.displayName} added to showroom fleet!');
    Navigator.of(context).pop(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AddVehicleHeader(
                      currentStep: _currentStep,
                      onBack: () => _currentStep > 1
                          ? setState(() => _currentStep--)
                          : Navigator.of(context).pop(),
                    ),
                    AddVehicleStepperBar(currentStep: _currentStep),
                    Padding(padding: const EdgeInsets.all(16), child: _buildCurrentStep()),
                  ],
                ),
              ),
            ),
            AddVehicleBottomBar(
              currentStep: _currentStep,
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return AddVehicleSpecsStep(
          selectedMake: _selectedMake,
          onMakeChanged: (m) => setState(() => _selectedMake = m),
          selectedModel: _selectedModel,
          onModelChanged: (m) => _selectedModel = m,
          selectedYear: _selectedYear,
          onYearChanged: (y) => setState(() => _selectedYear = y),
          color: _color,
          onColorChanged: (c) => _color = c,
          category: _category,
          onCategoryChanged: (c) => setState(() => _category = c),
          plateController: _plateController,
          onPlateChanged: () => setState(() {}),
          isAutomatic: _isAutomatic,
          onTransmissionChanged: (a) => setState(() => _isAutomatic = a),
          fuelType: _fuelType,
          onFuelTypeChanged: (f) => setState(() => _fuelType = f),
          seats: _seats,
          onSeatsChanged: (s) => setState(() => _seats = s),
          hasAc: _hasAc,
          onAcChanged: (a) => setState(() => _hasAc = a),
          selectedFeatures: _selectedFeatures,
          onFeatureToggled: (f) => setState(() => _selectedFeatures.contains(f) ? _selectedFeatures.remove(f) : _selectedFeatures.add(f)),
        );
      case 2:
        return AddVehiclePhotosStep(
          photoFrontFile: _photoFrontFile,
          onPickFront: () => _chooseMedia((f) => _photoFrontFile = f, hasExisting: _photoFrontFile != null),
          onRemoveFront: () => setState(() => _photoFrontFile = null),
          photoBackFile: _photoBackFile,
          onPickBack: () => _chooseMedia((f) => _photoBackFile = f, hasExisting: _photoBackFile != null),
          onRemoveBack: () => setState(() => _photoBackFile = null),
          photoSideFile: _photoSideFile,
          onPickSide: () => _chooseMedia((f) => _photoSideFile = f, hasExisting: _photoSideFile != null),
          onRemoveSide: () => setState(() => _photoSideFile = null),
          photoInteriorFile: _photoInteriorFile,
          onPickInterior: () => _chooseMedia((f) => _photoInteriorFile = f, hasExisting: _photoInteriorFile != null),
          onRemoveInterior: () => setState(() => _photoInteriorFile = null),
          regBookFile: _regBookFile,
          onPickRegBook: () => _chooseMedia((f) => _regBookFile = f, hasExisting: _regBookFile != null),
          onRemoveRegBook: () => setState(() => _regBookFile = null),
          tokenTaxFile: _tokenTaxFile,
          onPickTokenTax: () => _chooseMedia((f) => _tokenTaxFile = f, hasExisting: _tokenTaxFile != null),
          onRemoveTokenTax: () => setState(() => _tokenTaxFile = null),
          insuranceFile: _insuranceFile,
          onPickInsurance: () => _chooseMedia((f) => _insuranceFile = f, hasExisting: _insuranceFile != null),
          onRemoveInsurance: () => setState(() => _insuranceFile = null),
        );
      case 3:
        return AddVehicleRatesStep(
          enable1Hour: _enable1Hour,
          onToggle1Hour: (v) => setState(() => _enable1Hour = v),
          rate1HourController: _rate1HourController,
          enable3Hours: _enable3Hours,
          onToggle3Hours: (v) => setState(() => _enable3Hours = v),
          rate3HoursController: _rate3HoursController,
          enable6Hours: _enable6Hours,
          onToggle6Hours: (v) => setState(() => _enable6Hours = v),
          rate6HoursController: _rate6HoursController,
          enable24Hours: _enable24Hours,
          onToggle24Hours: (v) => setState(() => _enable24Hours = v),
          rate24HoursController: _rate24HoursController,
          enableWeekly: _enableWeekly,
          onToggleWeekly: (v) => setState(() => _enableWeekly = v),
          rateWeeklyController: _rateWeeklyController,
          supportSelfDrive: _supportSelfDrive,
          onToggleSelfDrive: (v) => setState(() => _supportSelfDrive = v),
          supportWithDriver: _supportWithDriver,
          onToggleWithDriver: (v) => setState(() => _supportWithDriver = v),
          driverAllowanceController: _driverAllowanceController,
          securityDepositController: _securityDepositController,
          advanceDepositController: _advanceDepositController,
          extraHourChargeController: _extraHourChargeController,
          fuelPolicy: _fuelPolicy,
          onFuelPolicyChanged: (f) => setState(() => _fuelPolicy = f),
        );
      case 4:
      default:
        return AddVehicleReviewStep(
          photoFrontFile: _photoFrontFile,
          selectedMake: _selectedMake,
          selectedModel: _selectedModel,
          category: _category,
          selectedYear: _selectedYear,
          color: _color,
          plateNumber: _plateController.text.trim(),
          isAutomatic: _isAutomatic,
          fuelType: _fuelType,
          seats: _seats,
          dailyRate: _getInt(_rate24HoursController, 8500),
          driverAllowance: _getInt(_driverAllowanceController, 2000),
          supportSelfDrive: _supportSelfDrive,
          supportWithDriver: _supportWithDriver,
          deposit: _getInt(_securityDepositController, 25000),
          advance: _getInt(_advanceDepositController, 2000),
          extraHour: _getInt(_extraHourChargeController, 600),
          fuelPolicy: _fuelPolicy,
        );
    }
  }
}
