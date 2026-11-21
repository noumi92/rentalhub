import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/media_picker_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_settings_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/add_vehicle_usecase.dart';
import '../services/vehicle_photo_upload_service.dart';
import '../widgets/add_vehicle/add_vehicle_doc_names.dart';
import '../widgets/add_vehicle/add_vehicle_step_content.dart';
import '../widgets/add_vehicle/add_vehicle_stepper_bar.dart';

/// Phase B (B1): builds a real [VehicleEntity] and saves it through [AddVehicleUseCase] instead of returning a mock vehicle.
/// Audit §5/C6: no prefilled sample data — plate and rates start empty and are validated before the wizard advances; all 7 picked files are uploaded (never silently discarded); the header + stepper stay pinned above the scrollable so the back arrow never scrolls away.
class OwnerAddVehicleView extends StatefulWidget {
  final ValueChanged<VehicleEntity>? onVehicleAdded;
  final String? shopId;
  const OwnerAddVehicleView({super.key, this.onVehicleAdded, this.shopId});

  @override
  State<OwnerAddVehicleView> createState() => _OwnerAddVehicleViewState();
}

class _OwnerAddVehicleViewState extends State<OwnerAddVehicleView> {
  int _currentStep = 1;
  bool _frontPhotoError = false;

  // Step 1: Specs, Capacity, AC & Extra Features
  String _selectedMake = 'Toyota', _selectedModel = 'Corolla Altis Grande', _color = 'Super White', _category = 'Sedan', _fuelType = 'Petrol';
  int _selectedYear = 2023, _seats = 5;
  final _plateController = TextEditingController();
  bool _isAutomatic = true;
  final Set<String> _selectedFeatures = {'ABS Brakes', 'Dual Airbags', 'Bluetooth Audio', 'Power Windows', 'GPS Tracking'};

  // Step 2: Photos (Camera + Gallery + Remove)
  XFile? _photoFrontFile, _photoBackFile, _photoSideFile, _photoInteriorFile;
  XFile? _regBookFile, _tokenTaxFile, _insuranceFile;

  // Step 3: Rates & Policies — start empty (audit §5/C6): no sample rates, deposit or allowance.
  bool _enable1Hour = true, _enable3Hours = true, _enable6Hours = true, _enable24Hours = true, _enableWeekly = true, _enableMonthly = true;
  final _rate1HourController = TextEditingController(), _rate3HoursController = TextEditingController(), _rate6HoursController = TextEditingController(), _rate24HoursController = TextEditingController(), _rateWeeklyController = TextEditingController(), _rateMonthlyController = TextEditingController();
  // Audit §5 finish (O07): out-city day rate, prefilled from the entered full-day rate (mirrored live in the rates widget); the in-city day rate IS the 24h package rate, so it shares _rate24HoursController.
  final _outCityDayRateController = TextEditingController();
  bool _supportSelfDrive = true, _supportWithDriver = true;
  final _securityDepositController = TextEditingController(), _advanceDepositController = TextEditingController(), _extraHourChargeController = TextEditingController();
  String _fuelPolicy = 'Same to Same';
  // Worker A (2026-11-21): the shop's booking-settings driver rate (Rs/day) — the review step's with-driver daily rate. The per-car driver allowance field is gone; the rate lives in booking settings and is never stored on the new vehicle.
  int? _driverRatePerDayPkr;

  @override void initState() { super.initState(); BookingSettingsDataSource().getSettings(widget.shopId ?? currentShopId()).then((s) { if (mounted) setState(() => _driverRatePerDayPkr = s.driverRatePerDayPkr); }); }

  @override
  void dispose() {
    for (final c in [_plateController, _rate1HourController, _rate3HoursController, _rate6HoursController, _rate24HoursController, _rateWeeklyController, _rateMonthlyController, _outCityDayRateController, _securityDepositController, _advanceDepositController, _extraHourChargeController]) {
      c.dispose();
    }
    super.dispose();
  }

  void _chooseMedia(Function(XFile?) onSet, {bool hasExisting = false}) {
    MediaPickerHelper.showMediaSourceSheet(context: context, onImageSelected: (f) => setState(() => onSet(f)), hasExistingFile: hasExisting);
  }

  int _getInt(TextEditingController ctrl, int fallback) => int.tryParse(ctrl.text.trim()) ?? fallback;

  // PakistaniValidators has no plate check, so the plate format is validated here: 2–4 letters, then digits, hyphens optional (LEA-23-4567, ICT-9912, LHR-24-1234).
  static bool _isValidPlate(String plate) => RegExp(r'^[A-Z]{2,4}-?\d{1,2}-?\d{1,4}$').hasMatch(plate.trim().toUpperCase());

  bool _validateStep() {
    final l10n = AppLocalizations.of(context)!;
    if (_currentStep == 1) {
      if (_selectedModel.trim().isEmpty) return _stepErr(l10n.addVehicleModelRequired);
      final plate = _plateController.text.trim();
      if (plate.isEmpty || !_isValidPlate(plate)) return _stepErr(l10n.addVehiclePlateRequired);
    } else if (_currentStep == 2) {
      // Audit §5 (spec O8): at least the front photo is required. The error is surfaced on the step itself (inline banner naming the front photo), not only at save.
      if (_photoFrontFile == null) {
        setState(() => _frontPhotoError = true);
        return false;
      }
    } else if (_currentStep == 3) {
      return _validateRates(l10n);
    }
    return true;
  }

  bool _validateRates(AppLocalizations l10n) {
    final fields = <(bool, TextEditingController, String, bool)>[
      (_enable1Hour, _rate1HourController, l10n.addVehicleRate1Hour, false), (_enable3Hours, _rate3HoursController, l10n.addVehicleRate3Hours, false),
      (_enable6Hours, _rate6HoursController, l10n.addVehicleRate6Hours, false), (_enable24Hours, _rate24HoursController, l10n.addVehicleRateFullDay, false),
      (_enableWeekly, _rateWeeklyController, l10n.addVehicleRateWeekly, false), (_enableMonthly, _rateMonthlyController, l10n.addVehicleRateMonthly, false),
      (true, _outCityDayRateController, l10n.addVehicleOutCityDayRate, false), (true, _securityDepositController, l10n.addVehicleSecurityDepositSelfDrive, true), (true, _advanceDepositController, l10n.addVehicleAdvanceFee, true),
      (true, _extraHourChargeController, l10n.addVehicleExtraHourCharge, false),];
    for (final (enabled, ctrl, label, allowZero) in fields) {
      if (!enabled) continue;
      final err = PakistaniValidators.validateRentalRate(ctrl.text, label: label, allowZero: allowZero);
      if (err != null) return _stepErr(err);
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
    // Phase B (B3): fix the vehicle id before the photo upload so a failed upload can be queued against this vehicle.
    final vehicleId = 'v-${DateTime.now().millisecondsSinceEpoch}';
    // Audit §5: upload ALL picked files — the old code uploaded only the front photo and silently discarded the other 6.
    final uploads = await VehiclePhotoUploadService.uploadAllVehicleFiles(shopId: shopId, vehicleId: vehicleId, files: {'imageUrl': _photoFrontFile, 'photoBackUrl': _photoBackFile, 'photoSideUrl': _photoSideFile, 'photoInteriorUrl': _photoInteriorFile, 'regBookUrl': _regBookFile, 'tokenTaxUrl': _tokenTaxFile, 'insuranceUrl': _insuranceFile});
    final imageUrl = uploads['imageUrl'] ?? _photoFrontFile?.path;
    final vehicle = VehicleEntity(
      vehicleId: vehicleId,
      shopId: shopId, make: _selectedMake, model: _selectedModel, year: _selectedYear, plateNumber: _plateController.text.trim(),
      category: _category, transmission: _isAutomatic ? 'Automatic' : 'Manual', fuelType: _fuelType, seats: _seats,
      isSelfDriveAvailable: _supportSelfDrive, isWithDriverAvailable: _supportWithDriver,
      rates: VehicleRatesEntity(
        hourly1: _enable1Hour ? _getInt(_rate1HourController, 0) : null,
        hourly3: _enable3Hours ? _getInt(_rate3HoursController, 0) : null,
        hourly6: _enable6Hours ? _getInt(_rate6HoursController, 0) : null,
        daily24: _getInt(_rate24HoursController, 0), outOfCityDaily: _getInt(_outCityDayRateController, 0)),
      imageUrl: imageUrl, color: _color, features: _selectedFeatures.toList(),
      // Audit §5 (integration): link the other six uploads — without these fields their URLs were uploaded but lost.
      photoBackUrl: uploads['photoBackUrl'], photoSideUrl: uploads['photoSideUrl'], photoInteriorUrl: uploads['photoInteriorUrl'],
      regBookUrl: uploads['regBookUrl'], tokenTaxUrl: uploads['tokenTaxUrl'], insuranceUrl: uploads['insuranceUrl'],
      weeklyRate: _enableWeekly ? _getInt(_rateWeeklyController, 0) : null,
      monthlyRate: _enableMonthly ? _getInt(_rateMonthlyController, 0) : null,
      securityDepositPkr: _getInt(_securityDepositController, 0), advanceRequiredPkr: _getInt(_advanceDepositController, 0),
      extraHourPkr: _getInt(_extraHourChargeController, 0), fuelPolicy: _fuelPolicy,
    );
    try { await sl<AddVehicleUseCase>()(shopId: shopId, vehicle: vehicle); } catch (e) {
      // Freemium 3-car limit and other save failures surface here.
      if (mounted) _stepErr(e.toString());
      return;
    }
    if (!mounted) return;
    widget.onVehicleAdded?.call(vehicle);
    // Audit §5 (O10): a saved car lands on the published-confirmation screen (View in App / Copy Link / Share), not a pop + snackbar. No router in tests: fall back to the pop.
    try {
      context.pushReplacement(RouteNames.ownerVehiclePublished.replaceFirst(':vehicleId', vehicle.vehicleId));
    } catch (_) {
      if (mounted) Navigator.of(context).pop(vehicle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // C1: MinimalAppBar owns the top inset; a second SafeArea would add a dead navy band above the header.
        top: false,
        child: Column(
          children: [
            // Audit §5: the header + stepper sit above the scrollable (as Rate Matrix does with PricingHeader), so the back arrow stays visible on long steps.
            AddVehicleHeader(
              currentStep: _currentStep,
              onBack: () => _currentStep > 1 ? setState(() => _currentStep--) : Navigator.of(context).pop(),
            ),
            AddVehicleStepperBar(currentStep: _currentStep),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(padding: const EdgeInsets.all(16), child: _buildCurrentStep()),
              ),
            ),
            AddVehicleBottomBar(currentStep: _currentStep, onPressed: _next),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return AddVehicleSpecsStep(
          selectedMake: _selectedMake, onMakeChanged: (m) => setState(() => _selectedMake = m),
          selectedModel: _selectedModel, onModelChanged: (m) => setState(() => _selectedModel = m),
          selectedYear: _selectedYear, onYearChanged: (y) => setState(() => _selectedYear = y),
          color: _color, onColorChanged: (c) => setState(() => _color = c),
          category: _category, onCategoryChanged: (c) => setState(() => _category = c),
          plateController: _plateController, onPlateChanged: () => setState(() {}),
          isAutomatic: _isAutomatic, onTransmissionChanged: (a) => setState(() => _isAutomatic = a),
          fuelType: _fuelType, onFuelTypeChanged: (f) => setState(() => _fuelType = f),
          seats: _seats, onSeatsChanged: (s) => setState(() => _seats = s),
          selectedFeatures: _selectedFeatures,
          onFeatureToggled: (f) => setState(() => _selectedFeatures.contains(f) ? _selectedFeatures.remove(f) : _selectedFeatures.add(f)),
        );
      case 2:
        return AddVehiclePhotosStep(
          photoFrontFile: _photoFrontFile,
          onPickFront: () => _chooseMedia((f) { _photoFrontFile = f; _frontPhotoError = false; }, hasExisting: _photoFrontFile != null),
          onRemoveFront: () => setState(() => _photoFrontFile = null),
          photoBackFile: _photoBackFile, onPickBack: () => _chooseMedia((f) => _photoBackFile = f, hasExisting: _photoBackFile != null),
          onRemoveBack: () => setState(() => _photoBackFile = null),
          photoSideFile: _photoSideFile, onPickSide: () => _chooseMedia((f) => _photoSideFile = f, hasExisting: _photoSideFile != null),
          onRemoveSide: () => setState(() => _photoSideFile = null),
          photoInteriorFile: _photoInteriorFile, onPickInterior: () => _chooseMedia((f) => _photoInteriorFile = f, hasExisting: _photoInteriorFile != null),
          onRemoveInterior: () => setState(() => _photoInteriorFile = null),
          regBookFile: _regBookFile, onPickRegBook: () => _chooseMedia((f) => _regBookFile = f, hasExisting: _regBookFile != null),
          onRemoveRegBook: () => setState(() => _regBookFile = null),
          tokenTaxFile: _tokenTaxFile, onPickTokenTax: () => _chooseMedia((f) => _tokenTaxFile = f, hasExisting: _tokenTaxFile != null),
          onRemoveTokenTax: () => setState(() => _tokenTaxFile = null),
          insuranceFile: _insuranceFile, onPickInsurance: () => _chooseMedia((f) => _insuranceFile = f, hasExisting: _insuranceFile != null),
          onRemoveInsurance: () => setState(() => _insuranceFile = null),
          frontPhotoError: _frontPhotoError,
        );
      case 3:
        return AddVehicleRatesStep(
          enable1Hour: _enable1Hour, onToggle1Hour: (v) => setState(() => _enable1Hour = v), rate1HourController: _rate1HourController,
          enable3Hours: _enable3Hours, onToggle3Hours: (v) => setState(() => _enable3Hours = v), rate3HoursController: _rate3HoursController,
          enable6Hours: _enable6Hours, onToggle6Hours: (v) => setState(() => _enable6Hours = v), rate6HoursController: _rate6HoursController,
          enable24Hours: _enable24Hours, onToggle24Hours: (v) => setState(() => _enable24Hours = v), rate24HoursController: _rate24HoursController,
          enableWeekly: _enableWeekly, onToggleWeekly: (v) => setState(() => _enableWeekly = v), rateWeeklyController: _rateWeeklyController, enableMonthly: _enableMonthly, onToggleMonthly: (v) => setState(() => _enableMonthly = v), rateMonthlyController: _rateMonthlyController,
          outCityDayRateController: _outCityDayRateController,
          supportSelfDrive: _supportSelfDrive, onToggleSelfDrive: (v) => setState(() => _supportSelfDrive = v),
          supportWithDriver: _supportWithDriver, onToggleWithDriver: (v) => setState(() => _supportWithDriver = v),
          securityDepositController: _securityDepositController,
          advanceDepositController: _advanceDepositController, extraHourChargeController: _extraHourChargeController,
          fuelPolicy: _fuelPolicy, onFuelPolicyChanged: (f) => setState(() => _fuelPolicy = f),
        );
      case 4:
      default:
        return AddVehicleReviewStep(
          photoFrontFile: _photoFrontFile,
          selectedMake: _selectedMake, selectedModel: _selectedModel, category: _category, selectedYear: _selectedYear, color: _color,
          plateNumber: _plateController.text.trim(),
          isAutomatic: _isAutomatic, fuelType: _fuelType, seats: _seats,
          dailyRate: _getInt(_rate24HoursController, 0), driverRatePerDayPkr: _driverRatePerDayPkr, monthlyRate: _getInt(_rateMonthlyController, 0),
          supportSelfDrive: _supportSelfDrive, supportWithDriver: _supportWithDriver,
          deposit: _getInt(_securityDepositController, 0), advance: _getInt(_advanceDepositController, 0),
          extraHour: _getInt(_extraHourChargeController, 0), fuelPolicy: _fuelPolicy,
          documentNames: pickedVehicleDocNames(AppLocalizations.of(context)!, photoBackFile: _photoBackFile, photoSideFile: _photoSideFile, photoInteriorFile: _photoInteriorFile, regBookFile: _regBookFile, tokenTaxFile: _tokenTaxFile, insuranceFile: _insuranceFile),
        );
    }
  }
}
