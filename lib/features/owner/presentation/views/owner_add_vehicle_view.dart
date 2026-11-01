import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/media_picker_helper.dart';
import '../constants/owner_vehicle_constants.dart';
import '../widgets/add_vehicle/add_vehicle_stepper_bar.dart';
import '../widgets/add_vehicle/vehicle_photos_step_widget.dart';
import '../widgets/add_vehicle/vehicle_rates_step_widget.dart';
import '../widgets/add_vehicle/vehicle_review_step_widget.dart';
import '../widgets/add_vehicle/vehicle_specs_step_widget.dart';

class OwnerAddVehicleView extends StatefulWidget {
  final ValueChanged<MockVehicle>? onVehicleAdded;
  const OwnerAddVehicleView({super.key, this.onVehicleAdded});

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

  void _next() {
    if (!_validateStep()) return;
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      final newVehicle = MockVehicle(
        id: 'v-${DateTime.now().millisecondsSinceEpoch}',
        make: _selectedMake,
        model: _selectedModel,
        year: _selectedYear,
        plate: _plateController.text.trim().isEmpty ? 'LEA-23-4567' : _plateController.text.trim(),
        city: 'Lahore',
        shopName: 'Al-Falah Rent a Car',
        shopAddress: 'DHA Phase 5, Lahore',
        rating: 5.0,
        tripCount: 0,
        dailyRate: _getInt(_rate24HoursController, 8500),
        hourlyRate1: _getInt(_rate1HourController, 1200),
        hourlyRate3: _getInt(_rate3HoursController, 3000),
        hourlyRate6: _getInt(_rate6HoursController, 5500),
        deposit: _getInt(_securityDepositController, 25000),
        fuelType: _fuelType,
        transmission: _isAutomatic ? 'Automatic' : 'Manual',
        seats: _seats,
        category: _category,
        hasAC: _hasAc,
        features: _selectedFeatures.toList(),
        status: 'Available',
        imageUrl: _photoFrontFile != null ? _photoFrontFile!.path : 'assets/images/white_sedan_hero.png',
      );

      widget.onVehicleAdded?.call(newVehicle);
      AppFeedback.showSuccess(context, '${newVehicle.name} added to showroom fleet!');
      Navigator.of(context).pop(newVehicle);
    }
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
                    CustomCurvedHeader(
                      height: 100,
                      leadingWidget: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => _currentStep > 1 ? setState(() => _currentStep--) : Navigator.of(context).pop(),
                      ),
                      titleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getTitle(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(_getSubtitle(), style: const TextStyle(color: AppColors.textLavender, fontSize: 12)),
                        ],
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                          child: Text('Step $_currentStep of 4', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    AddVehicleStepperBar(currentStep: _currentStep),
                    Padding(padding: const EdgeInsets.all(16), child: _buildCurrentStep()),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border)), boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, -3))]),
              child: DebouncedButton(
                text: _currentStep == 4 ? 'Confirm & Publish Vehicle' : 'Next Step',
                icon: _currentStep == 4 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                onPressed: () async => _next(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() => const {1: 'Add Vehicle - Specs', 2: 'Car Photos & Docs', 3: 'Rental Rates & Policy'}[_currentStep] ?? 'Review & Publish';
  String _getSubtitle() => const {1: 'Capacity, AC, features & specs', 2: '4-angle photos, book & excise tax', 3: 'Hourly rates, deposit & fuel policy'}[_currentStep] ?? 'Verify vehicle details before listing';

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return VehicleSpecsStepWidget(
          selectedMake: _selectedMake,
          onMakeChanged: (m) => setState(() => _selectedMake = m),
          makes: OwnerVehicleConstants.makes,
          selectedModel: _selectedModel,
          onModelChanged: (m) => _selectedModel = m,
          selectedYear: _selectedYear,
          onYearChanged: (y) => setState(() => _selectedYear = y),
          color: _color,
          onColorChanged: (c) => _color = c,
          category: _category,
          onCategoryChanged: (c) => setState(() => _category = c),
          categories: OwnerVehicleConstants.categories,
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
        return VehiclePhotosStepWidget(
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
        return VehicleRatesStepWidget(
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
          fuelPolicies: OwnerVehicleConstants.fuelPolicies,
        );
      case 4:
      default:
        return VehicleReviewStepWidget(
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
