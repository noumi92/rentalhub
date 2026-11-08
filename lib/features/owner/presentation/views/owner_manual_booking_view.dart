import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../services/walk_in_booking_service.dart';
import '../widgets/guarantor_picker.dart';
import '../widgets/manual_booking_customer_fields.dart';
import '../widgets/manual_booking_package_selector.dart';
import '../widgets/manual_booking_vehicle_section.dart';
import 'owner_handover_signature_view.dart';

class OwnerManualBookingView extends StatefulWidget {
  final String? prefilledCnic;
  // #18: booking for an existing customer (from the Customers list) prefills
  // name + phone as well as the CNIC; all three arrive as query params.
  final String? prefilledName;
  final String? prefilledPhone;
  final VoidCallback? onBack;

  const OwnerManualBookingView({
    super.key,
    this.prefilledCnic,
    this.prefilledName,
    this.prefilledPhone,
    this.onBack,
  });

  @override
  State<OwnerManualBookingView> createState() => _OwnerManualBookingViewState();
}

class _OwnerManualBookingViewState extends State<OwnerManualBookingView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cnicController;
  // Audit §12 (Critical): no demo identity defaults — controllers start empty
  // and are prefilled only from real query params / scan; submit validates.
  final _depositController = TextEditingController();

  List<VehicleEntity> _vehicles = [];
  VehicleEntity? _selectedVehicle;
  VehiclePackageEntity? _selectedPackage;
  bool _isWithDriver = false;
  bool _isLoadingVehicles = true;
  String? _vehiclesError;
  bool _isCreating = false;
  GuarantorSelection? _guarantor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefilledName ?? '');
    _phoneController = TextEditingController(text: widget.prefilledPhone ?? '');
    _cnicController = TextEditingController(text: widget.prefilledCnic ?? '');
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
      final packages = v?.enabledPackages ?? const [];
      _selectedPackage = packages.isNotEmpty ? packages.first : null;
      final deposit = v?.securityDepositPkr;
      if (deposit != null) _depositController.text = deposit.toString();
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
          if (cars.isNotEmpty) _selectVehicle(cars.first);
        });
      }
    } catch (e) {
      // Audit C4: a failed vehicle load is a visible error with a retry, never a silent empty dropdown.
      if (mounted) setState(() => _vehiclesError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  Future<void> _createBooking() async {
  final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    // Phase B (B2): the counter total comes from the chosen package, not from a typed number.
    final rentAmount = ManualBookingPackageSelector.totalFor(vehicle: _selectedVehicle, package: _selectedPackage, isWithDriver: _isWithDriver);

    if (name.isEmpty || phone.isEmpty || cnic.isEmpty) {
      AppFeedback.showError(context, l10n.manualBookingCompleteDetails);
      return;
    }
    if (_selectedVehicle == null || _selectedPackage == null) {
      AppFeedback.showError(context, l10n.manualBookingSelectVehicle);
      return;
    }
    // Phase B (D2): a blacklisted CNIC cannot book at the counter either — the scan screen is not the only way in.
    // Integration: the blacklist lookup itself is inside the guard —
    // if it throws (Firestore unreachable), the booking is refused
    // with an error instead of proceeding unchecked or crashing on
    // an unhandled async error. The save-side check in
    // saveWalkInCustomer is only a backstop: the booking service
    // swallows save errors by design, so this pre-submit check is
    // the block that actually stops a blacklisted walk-in.
    bool blacklisted;
    try {
      blacklisted =
          await sl<BlacklistRemoteDataSource>().isCnicBlacklisted(cnic);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context, l10n.manualBookingCreateFailed(e.toString()));
      }
      return;
    }
    if (blacklisted) {
      if (mounted) AppFeedback.showError(context, l10n.manualBookingBlacklisted);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final booking = await WalkInBookingService.createWalkInBooking(name: name, phone: phone, cnic: cnic, guarantor: _guarantor, vehicle: _selectedVehicle!, package: _selectedPackage!, isWithDriver: _isWithDriver, rentAmount: rentAmount);

      if (mounted) {
        AppFeedback.showSuccess(context, l10n.manualBookingRegistered(booking.bookingId));
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OwnerHandoverSignatureView(booking: booking.copyWith(status: 'paid'))));
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.manualBookingCreateFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(l10n.manualBookingCustomerSection),
                    ManualBookingCustomerFields(nameController: _nameController, phoneController: _phoneController, cnicController: _cnicController),
                    const SizedBox(height: 18),
                    _sectionHeader(l10n.manualBookingGuarantorSection),
                    GuarantorPicker(onChanged: (g) => setState(() => _guarantor = g)),
                    const SizedBox(height: 18),
                    _sectionHeader(l10n.manualBookingVehicleSection),
                    if (_vehiclesError != null)
                      ManualBookingLoadErrorCard(message: l10n.fleetLoadError(_vehiclesError!), onRetry: _loadVehicles)
                    else
                      ManualBookingVehicleSection(
                        isLoadingVehicles: _isLoadingVehicles, vehicles: _vehicles, selectedVehicle: _selectedVehicle, onVehicleChanged: (v) => _selectVehicle(v),
                        selectedPackage: _selectedPackage, onPackageChanged: (p) => setState(() => _selectedPackage = p),
                        isWithDriver: _isWithDriver, onDriverModeChanged: (v) => setState(() => _isWithDriver = v), depositController: _depositController,
                      ),
                    const SizedBox(height: 24),
                    DebouncedButton(text: _isCreating ? l10n.manualBookingCreating : l10n.manualBookingConfirm, icon: Icons.check_circle_rounded, isLoading: _isCreating, onPressed: _createBooking),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}
