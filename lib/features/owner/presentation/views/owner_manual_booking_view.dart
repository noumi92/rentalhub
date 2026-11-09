import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../services/walk_in_booking_service.dart';
import '../widgets/guarantor_picker.dart';
import '../widgets/manual_booking_form_body.dart';
import '../widgets/manual_booking_package_selector.dart';
import 'owner_manual_booking_confirm_view.dart';

/// Audit §5 item 1 (O16/O17 p.7): the manual booking entry — customer,
/// vehicle + package, pickup/return date+time pickers, In-City /
/// Out-City toggle — then "Next" to the confirm step.
class OwnerManualBookingView extends StatefulWidget {
  final String? prefilledCnic;
  // #18 + audit §5 item 16: name/phone/CNIC (Customers list) and
  // vehicle/dates/trip type (request-to-manual) arrive as query params.
  final String? prefilledName;
  final String? prefilledPhone;
  final String? prefilledVehicleId;
  final DateTime? prefilledPickupTime;
  final DateTime? prefilledReturnTime;
  final String? prefilledTripType;
  final VoidCallback? onBack;

  const OwnerManualBookingView({
    super.key,
    this.prefilledCnic,
    this.prefilledName,
    this.prefilledPhone,
    this.prefilledVehicleId,
    this.prefilledPickupTime,
    this.prefilledReturnTime,
    this.prefilledTripType,
    this.onBack,
  });

  @override
  State<OwnerManualBookingView> createState() => _OwnerManualBookingViewState();
}

class _OwnerManualBookingViewState extends State<OwnerManualBookingView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cnicController;
  // Audit §12: no demo identity defaults — controllers start empty
  // and are prefilled only from real query params / scan.
  final _depositController = TextEditingController();

  List<VehicleEntity> _vehicles = [];
  VehicleEntity? _selectedVehicle;
  VehiclePackageEntity? _selectedPackage;
  // 09b §2: the fixed route chosen for this out-of-city trip.
  FixedRouteEntity? _selectedRoute;
  bool _isWithDriver = false;
  bool _isLoadingVehicles = true;
  String? _vehiclesError;
  bool _isChecking = false;
  GuarantorSelection? _guarantor;

  late DateTime _pickupTime;
  late DateTime _returnTime;
  bool _returnEdited = false;
  late bool _isOutOfCity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefilledName ?? '');
    _phoneController = TextEditingController(text: widget.prefilledPhone ?? '');
    _cnicController = TextEditingController(text: widget.prefilledCnic ?? '');
    _pickupTime = widget.prefilledPickupTime ??
        DateTime.now().add(const Duration(hours: 1));
    _returnTime = widget.prefilledReturnTime ??
        _pickupTime.add(const Duration(hours: 24));
    _returnEdited = widget.prefilledReturnTime != null;
    _isOutOfCity = widget.prefilledTripType == 'out_of_city';
    // Keep the step indicator live as the owner types.
    _nameController.addListener(_refreshStep);
    _phoneController.addListener(_refreshStep);
    _cnicController.addListener(_refreshStep);
    _loadVehicles();
  }

  void _refreshStep() {
    if (mounted) setState(() {});
  }

  /// 1-based wizard step: 1 Customer, 2 Vehicle+Package, 3 Confirm.
  int get _currentStep {
    final customerDone = _nameController.text.trim().isNotEmpty && _phoneController.text.trim().isNotEmpty && _cnicController.text.trim().isNotEmpty;
    if (!customerDone) return 1;
    if (_selectedVehicle == null || _selectedPackage == null) return 2;
    return 3;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  void _selectVehicle(VehicleEntity? v) {
    setState(() {
      _selectedVehicle = v;
      _selectedRoute = null;
      final packages = v?.enabledPackages ?? const [];
      _selectedPackage = packages.isNotEmpty ? packages.first : null;
      final deposit = v?.securityDepositPkr;
      if (deposit != null) _depositController.text = deposit.toString();
      if (!_returnEdited && _selectedPackage != null) {
        _returnTime = ManualBookingPackageSelector.returnTimeFor(
            pickup: _pickupTime, package: _selectedPackage!);
      }
    });
  }

  void _onPickupChanged(DateTime next) {
    setState(() {
      _pickupTime = next;
      if (!_returnEdited && _selectedPackage != null) {
        _returnTime = ManualBookingPackageSelector.returnTimeFor(
            pickup: _pickupTime, package: _selectedPackage!);
      }
    });
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
      _vehiclesError = null;
    });
    try {
      final ds = sl<FleetRemoteDataSource>();
      final cars = await ds.getShopVehicles(currentShopId());
      if (mounted) {
        setState(() {
          _vehicles = cars;
          VehicleEntity? prefilled;
          for (final v in cars) {
            if (v.vehicleId == widget.prefilledVehicleId) prefilled = v;
          }
          _selectVehicle(
              prefilled ?? (cars.isNotEmpty ? cars.first : null));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _vehiclesError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  Future<void> _goToConfirm() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    if (name.isEmpty || phone.isEmpty || cnic.isEmpty) {
      AppFeedback.showError(context, l10n.manualBookingCompleteDetails);
      return;
    }
    if (_selectedVehicle == null || _selectedPackage == null) {
      AppFeedback.showError(context, l10n.manualBookingSelectVehicle);
      return;
    }
    // 09b §2: a fixed-route vehicle prices by its route — without one chosen there is no honest total, so block, don't fall back.
    if (_isOutOfCity && _selectedVehicle?.outCityMode == 'fixedRoute' && _selectedRoute == null) {
      AppFeedback.showError(context, l10n.outCityFixedRouteNone);
      return;
    }
    if (!_returnTime.isAfter(_pickupTime)) {
      AppFeedback.showError(context, l10n.manualBookingReturnAfterPickup);
      return;
    }
    // Phase B (D2): a blacklisted CNIC cannot book at the counter
    // either — the scan screen is not the only way in.
    setState(() => _isChecking = true);
    bool blacklisted;
    try {
      blacklisted =
          await WalkInBookingService.isCnicBlacklisted(cnic);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context, l10n.manualBookingCreateFailed(e.toString()));
      }
      setState(() => _isChecking = false);
      return;
    }
    setState(() => _isChecking = false);
    if (blacklisted) {
      if (mounted) AppFeedback.showError(context, l10n.manualBookingBlacklisted);
      return;
    }
    if (!mounted) return;
    OwnerManualBookingConfirmView.open(context, customerName: name, customerPhone: phone, customerCnic: cnic, guarantor: _guarantor, vehicle: _selectedVehicle!, package: _selectedPackage!, isWithDriver: _isWithDriver, isOutOfCity: _isOutOfCity, pickupTime: _pickupTime, returnTime: _returnTime, fixedRoute: _selectedRoute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: l10n.manualBookingTitle, subtitle: l10n.manualBookingSubtitle, onBack: widget.onBack),
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: ManualBookingStepIndicator(currentStep: _currentStep)),
            Expanded(
              child: ManualBookingFormBody(
                nameController: _nameController, phoneController: _phoneController, cnicController: _cnicController,
                onGuarantorChanged: (g) => setState(() => _guarantor = g),
                vehiclesError: _vehiclesError, onRetryLoad: _loadVehicles,
                isLoadingVehicles: _isLoadingVehicles, vehicles: _vehicles,
                selectedVehicle: _selectedVehicle, onVehicleChanged: (v) => _selectVehicle(v),
                selectedPackage: _selectedPackage,
                onPackageChanged: (p) => setState(() {
                  _selectedPackage = p;
                  if (!_returnEdited && p != null) {
                    _returnTime = ManualBookingPackageSelector.returnTimeFor(pickup: _pickupTime, package: p);
                  }
                }),
                isWithDriver: _isWithDriver, onDriverModeChanged: (v) => setState(() => _isWithDriver = v),
                depositController: _depositController,
                isOutOfCity: _isOutOfCity, pickupTime: _pickupTime, returnTime: _returnTime,
                onPickupChanged: _onPickupChanged,
                onReturnChanged: (next) => setState(() {
                  _returnTime = next;
                  _returnEdited = true;
                }),
                onTripTypeChanged: (v) => setState(() => _isOutOfCity = v),
                selectedFixedRoute: _selectedRoute, onFixedRouteChanged: (r) => setState(() => _selectedRoute = r),
                isChecking: _isChecking, onNext: _goToConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
