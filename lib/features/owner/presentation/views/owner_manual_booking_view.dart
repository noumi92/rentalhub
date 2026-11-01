import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
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
  final _rentController = TextEditingController(text: '8000');

  List<VehicleEntity> _vehicles = [];
  VehicleEntity? _selectedVehicle;
  bool _isLoadingVehicles = true;
  bool _isCreating = false;
  String _selectedPackage = 'Daily 24h';
  bool _isWithDriver = false;

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
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      final ds = sl<FleetRemoteDataSource>();
      final cars = await ds.getShopVehicles('shop-1');
      if (mounted) {
        setState(() {
          _vehicles = cars;
          if (cars.isNotEmpty) _selectedVehicle = cars.first;
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
    final rentAmount = int.tryParse(_rentController.text) ?? 8000;

    if (name.isEmpty || phone.isEmpty || cnic.isEmpty) {
      AppFeedback.showError(context, 'Please complete all customer details.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final ds = sl<BookingRemoteDataSource>();
      final booking = await ds.createBookingRequest(
        customerId: 'walkin-${DateTime.now().millisecondsSinceEpoch}',
        shopId: 'shop-1',
        vehicleId: _selectedVehicle?.vehicleId ?? 'v1',
        vehicleName: _selectedVehicle != null ? '${_selectedVehicle!.make} ${_selectedVehicle!.model}' : 'Showroom Car',
        customerName: name,
        customerPhone: phone,
        packageType: _selectedPackage,
        isWithDriver: _isWithDriver,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: rentAmount,
        advanceRequired: rentAmount,
      );

      // Immediately mark paid for walk-in cash transaction
      await ds.verifyPayment(bookingId: booking.bookingId, advanceAmount: rentAmount);

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
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Walk-in Booking Wizard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('Showroom Counter Direct Issue', style: TextStyle(color: AppColors.textLavender, fontSize: 12)),
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
                    _inputField(controller: _nameController, label: 'Customer Full Name', icon: Icons.person_rounded),
                    const SizedBox(height: 10),
                    _inputField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_rounded, keyboard: TextInputType.phone),
                    const SizedBox(height: 10),
                    _inputField(controller: _cnicController, label: 'NADRA CNIC', icon: Icons.badge_rounded, keyboard: TextInputType.number),
                    const SizedBox(height: 18),
                    _sectionHeader('Vehicle & Package Selection'),
                    if (_isLoadingVehicles)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<VehicleEntity>(
                            isExpanded: true,
                            value: _selectedVehicle,
                            hint: const Text('Select Showroom Vehicle'),
                            items: _vehicles.map((v) {
                              return DropdownMenuItem(
                                value: v,
                                child: Text('${v.make} ${v.model} (${v.year}) - ${v.plateNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedVehicle = v),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _inputField(controller: _rentController, label: 'Total Rent (Rs.)', icon: Icons.payments_rounded, keyboard: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _inputField(controller: _depositController, label: 'Security Deposit (Rs.)', icon: Icons.lock_clock_rounded, keyboard: TextInputType.number)),
                      ],
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
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.midnightNavy, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
