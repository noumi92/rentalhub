import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
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
  final VoidCallback? onBack;

  const OwnerManualBookingView({
    super.key,
    this.prefilledCnic,
    this.onBack,
  });

  @override
  State<OwnerManualBookingView> createState() => _OwnerManualBookingViewState();
}

class _OwnerManualBookingViewState extends State<OwnerManualBookingView> {
  final _nameController = TextEditingController(text: 'Walk-in Customer');
  final _phoneController = TextEditingController(text: '0300-1122334');
  late final TextEditingController _cnicController;
  final _depositController = TextEditingController(text: '15000');

  List<VehicleEntity> _vehicles = [];
  VehicleEntity? _selectedVehicle;
  VehiclePackageEntity? _selectedPackage;
  bool _isWithDriver = false;
  bool _isLoadingVehicles = true;
  bool _isCreating = false;
  GuarantorSelection? _guarantor;

  @override
  void initState() {
    super.initState();
    _cnicController = TextEditingController(text: widget.prefilledCnic ?? '35201-1234567-1');
    _loadVehicles();
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
    try {
      final ds = sl<FleetRemoteDataSource>();
      final cars = await ds.getShopVehicles('shop-1');
      if (mounted) {
        setState(() {
          _vehicles = cars;
          if (cars.isNotEmpty) _selectVehicle(cars.first);
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  Future<void> _createBooking() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    // Phase B (B2): the counter total comes from the chosen package,
    // not from a typed number.
    final rentAmount = ManualBookingPackageSelector.totalFor(
      vehicle: _selectedVehicle,
      package: _selectedPackage,
      isWithDriver: _isWithDriver,
    );

    if (name.isEmpty || phone.isEmpty || cnic.isEmpty) {
      AppFeedback.showError(context, 'Please complete all customer details.');
      return;
    }
    if (_selectedVehicle == null || _selectedPackage == null) {
      AppFeedback.showError(context, 'Please select a vehicle and package.');
      return;
    }
    // Phase B (D2): a blacklisted CNIC cannot book at the counter
    // either — the scan screen is not the only way in.
    if (await sl<BlacklistRemoteDataSource>().isCnicBlacklisted(cnic)) {
      if (mounted) {
        AppFeedback.showError(context,
            'This CNIC is blacklisted — walk-in booking refused.');
      }
      return;
    }

    setState(() => _isCreating = true);
    try {
      final booking = await WalkInBookingService.createWalkInBooking(
        name: name,
        phone: phone,
        cnic: cnic,
        guarantor: _guarantor,
        vehicle: _selectedVehicle!,
        package: _selectedPackage!,
        isWithDriver: _isWithDriver,
        rentAmount: rentAmount,
      );

      if (mounted) {
        AppFeedback.showSuccess(context, 'Walk-in booking #${booking.bookingId} registered!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OwnerHandoverSignatureView(
              booking: booking.copyWith(status: 'paid'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Booking creation failed: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Walk-in Booking Wizard', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('Showroom Counter Direct Issue', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Customer KYC Details'),
                    ManualBookingCustomerFields(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      cnicController: _cnicController,
                    ),
                    const SizedBox(height: 18),
                    _sectionHeader('Guarantor (optional)'),
                    GuarantorPicker(
                      onChanged: (g) => setState(() => _guarantor = g),
                    ),
                    const SizedBox(height: 18),
                    _sectionHeader('Vehicle & Package Selection'),
                    ManualBookingVehicleSection(
                      isLoadingVehicles: _isLoadingVehicles,
                      vehicles: _vehicles,
                      selectedVehicle: _selectedVehicle,
                      onVehicleChanged: (v) => _selectVehicle(v),
                      selectedPackage: _selectedPackage,
                      onPackageChanged: (p) =>
                          setState(() => _selectedPackage = p),
                      isWithDriver: _isWithDriver,
                      onDriverModeChanged: (v) =>
                          setState(() => _isWithDriver = v),
                      depositController: _depositController,
                    ),
                    const SizedBox(height: 24),
                    DebouncedButton(
                      text: _isCreating ? 'Creating Walk-in Record...' : 'Confirm & Proceed to Handover',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isCreating,
                      onPressed: _createBooking,
                    ),
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
