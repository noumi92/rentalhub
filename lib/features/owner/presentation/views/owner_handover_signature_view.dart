import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../handover/presentation/cubit/handover_cubit.dart';
import '../widgets/operations/fuel_odometer_input_widget.dart';
import '../widgets/operations/dual_signature_pad_widget.dart';
import 'owner_contract_view.dart';

class OwnerHandoverSignatureView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerHandoverSignatureView({
    super.key,
    required this.booking,
    this.onBack,
  });

  @override
  State<OwnerHandoverSignatureView> createState() => _OwnerHandoverSignatureViewState();
}

class _OwnerHandoverSignatureViewState extends State<OwnerHandoverSignatureView> {
  final _odometerController = TextEditingController(text: '45200');
  String _selectedFuel = '4/4 (Full)';
  bool _customerSigned = false;
  bool _ownerSigned = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _completeHandover() async {
    final odo = int.tryParse(_odometerController.text.trim());
    if (odo == null || odo <= 0) {
      AppFeedback.showError(context, 'Please enter a valid odometer reading.');
      return;
    }

    if (!_customerSigned || !_ownerSigned) {
      AppFeedback.showError(context, 'Both customer and host must sign before vehicle departure.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final cubit = sl<HandoverCubit>();
      await cubit.completeHandoverOfflineFirst(
        bookingId: widget.booking.bookingId,
        shopName: widget.booking.shopName ?? 'Al-Falah Rent a Car',
        customerName: widget.booking.customerName ?? 'Customer',
        cnicNumber: '35201-1234567-1',
        vehicleDetails: widget.booking.vehicleName ?? 'Honda Civic RS Turbo',
        initialOdometer: odo,
        fuelLevel: _selectedFuel,
        damageNotes: ['Clean interior', 'Spare tire checked', 'Minor right door scratch noted'],
        customerSignatureSvg: '<svg>customer-vector-sig</svg>',
        ownerSignatureSvg: '<svg>host-vector-sig</svg>',
        isOnline: true,
      );

      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(bookingId: widget.booking.bookingId, status: 'active');

      if (mounted) {
        AppFeedback.showSuccess(context, 'Handover certified! Digital A4 rental contract generated.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OwnerContractView(
              booking: widget.booking.copyWith(status: 'active'),
              odometer: odo,
              fuelLevel: _selectedFuel,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Handover completion failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle Handover & Inspection', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  Text('#${widget.booking.bookingId} • ${widget.booking.vehicleName ?? "Vehicle"}', style: const TextStyle(color: AppColors.textLavender, fontSize: 11.5)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    FuelOdometerInputWidget(
                      odometerController: _odometerController,
                      selectedFuel: _selectedFuel,
                      onFuelSelected: (f) => setState(() => _selectedFuel = f),
                    ),
                    const SizedBox(height: 16),
                    DualSignaturePadWidget(
                      customerSigned: _customerSigned,
                      ownerSigned: _ownerSigned,
                      onCustomerSign: () {
                        setState(() => _customerSigned = !_customerSigned);
                        AppFeedback.showSuccess(context, _customerSigned ? 'Customer signature captured!' : 'Customer signature cleared');
                      },
                      onOwnerSign: () {
                        setState(() => _ownerSigned = !_ownerSigned);
                        AppFeedback.showSuccess(context, _ownerSigned ? 'Host signature captured!' : 'Host signature cleared');
                      },
                    ),
                    const SizedBox(height: 24),
                    DebouncedButton(
                      text: _isSaving ? 'Issuing Digital Contract...' : 'Certify Handover & Generate Contract',
                      icon: Icons.assignment_turned_in_rounded,
                      isLoading: _isSaving,
                      onPressed: _completeHandover,
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
}
