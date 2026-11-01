import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../widgets/operations/fuel_odometer_input_widget.dart';
import '../widgets/operations/settlement_summary_receipt_widget.dart';
import 'owner_customer_rating_view.dart';

class OwnerReturnSettlementView extends StatefulWidget {
  final BookingEntity booking;
  final int initialOdometer;
  final int kmAllowance;
  final int initialDeposit;
  final VoidCallback? onBack;

  const OwnerReturnSettlementView({
    super.key,
    required this.booking,
    this.initialOdometer = 45200,
    this.kmAllowance = 250,
    this.initialDeposit = 15000,
    this.onBack,
  });

  @override
  State<OwnerReturnSettlementView> createState() => _OwnerReturnSettlementViewState();
}

class _OwnerReturnSettlementViewState extends State<OwnerReturnSettlementView> {
  late final TextEditingController _returnOdometerController;
  String _returnFuel = '4/4 (Full)';
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    _returnOdometerController = TextEditingController(text: '${widget.initialOdometer + 310}');
    _returnOdometerController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _returnOdometerController.dispose();
    super.dispose();
  }

  int get _returnOdometer => int.tryParse(_returnOdometerController.text.trim()) ?? (widget.initialOdometer + 310);
  int get _totalKmDriven => (_returnOdometer - widget.initialOdometer).clamp(0, 99999);
  int get _excessKm => (_totalKmDriven - widget.kmAllowance).clamp(0, 99999);
  int get _excessPenalty => _excessKm * 25; // Rs. 25 per excess km
  int get _fuelDeficit => _returnFuel == '4/4 (Full)' ? 0 : (_returnFuel == '3/4 (75%)' ? 1500 : (_returnFuel == '2/4 (50%)' ? 3000 : 4500));
  int get _netRefund => (widget.initialDeposit - _excessPenalty - _fuelDeficit).clamp(0, 99999);

  Future<void> _finalizeReturn() async {
    setState(() => _isFinalizing = true);
    try {
      final bookingDs = sl<BookingRemoteDataSource>();
      await bookingDs.updateBookingStatus(
        bookingId: widget.booking.bookingId,
        status: 'completed',
      );

      final fleetDs = sl<FleetRemoteDataSource>();
      await fleetDs.updateVehicleStatus(
        vehicleId: widget.booking.vehicleId,
        status: 'available',
      );

      if (mounted) {
        AppFeedback.showSuccess(context, 'Vehicle returned! Deposit settled and car restored to live fleet.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OwnerCustomerRatingView(
              booking: widget.booking.copyWith(status: 'completed'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Finalizing return failed: $e');
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
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
                  const Text('Vehicle Return & Settlement', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  Text('Trip Audit #${widget.booking.bookingId}', style: const TextStyle(color: AppColors.textLavender, fontSize: 11.5)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    FuelOdometerInputWidget(
                      title: 'Return Telemetry Inspection',
                      odometerController: _returnOdometerController,
                      selectedFuel: _returnFuel,
                      onFuelSelected: (f) => setState(() => _returnFuel = f),
                    ),
                    const SizedBox(height: 16),
                    SettlementSummaryReceiptWidget(
                      totalKm: _totalKmDriven,
                      excessKm: _excessKm,
                      excessKmPenalty: _excessPenalty,
                      fuelDeficitFee: _fuelDeficit,
                      overtimeFee: 0,
                      securityDeposit: widget.initialDeposit,
                      netRefund: _netRefund,
                    ),
                    const SizedBox(height: 24),
                    DebouncedButton(
                      text: _isFinalizing ? 'Finalizing Settlement...' : 'Finalize Return & Settle Deposit',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isFinalizing,
                      onPressed: _finalizeReturn,
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
