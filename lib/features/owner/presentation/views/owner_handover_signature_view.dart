import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../handover/data/datasources/pdf_contract_generator.dart';
import '../../../handover/presentation/cubit/handover_cubit.dart';
import '../widgets/handover_damage_notes_editor.dart';
import '../widgets/operations/dual_signature_pad_widget.dart';
import '../widgets/operations/fuel_odometer_input_widget.dart';
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
  State<OwnerHandoverSignatureView> createState() =>
      _OwnerHandoverSignatureViewState();
}

class _OwnerHandoverSignatureViewState
    extends State<OwnerHandoverSignatureView> {
  final _odometerController = TextEditingController(text: '45200');
  final _customerSig = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final _ownerSig = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String _selectedFuel = '4/4 (Full)';
  List<String> _damageNotes = const [];
  bool _isSaving = false;
  String _shopName = '';
  int _securityDeposit = 0;

  @override
  void initState() {
    super.initState();
    _shopName = widget.booking.shopName ?? '';
    _loadShopAndVehicle();
  }

  Future<void> _loadShopAndVehicle() async {
    try {
      final shopId = widget.booking.shopId;
      if (_shopName.isEmpty && shopId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .get();
        final name = (doc.data()?['name'] ?? doc.data()?['shopName']) as String?;
        if (name != null && name.isNotEmpty && mounted) {
          setState(() => _shopName = name);
        }
      }
      final vehicles =
          await sl<FleetRemoteDataSource>().getShopVehicles(shopId);
      final vehicle = vehicles
          .where((v) => v.vehicleId == widget.booking.vehicleId)
          .toList();
      if (vehicle.isNotEmpty && mounted) {
        setState(
            () => _securityDeposit = vehicle.first.securityDepositPkr ?? 0);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _customerSig.dispose();
    _ownerSig.dispose();
    super.dispose();
  }

  Future<void> _completeHandover() async {
    final odo = int.tryParse(_odometerController.text.trim());
    if (odo == null || odo <= 0) {
      AppFeedback.showError(context, 'Please enter a valid odometer reading.');
      return;
    }

    if (_customerSig.isEmpty || _ownerSig.isEmpty) {
      AppFeedback.showError(context,
          'Both customer and host must sign on the pads before vehicle departure.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final customerPng = await _customerSig.toPngBytes();
      final ownerPng = await _ownerSig.toPngBytes();
      final booking = widget.booking;
      final entity = await sl<HandoverCubit>().completeHandoverOfflineFirst(
        bookingId: booking.bookingId,
        shopId: booking.shopId,
        shopName: _shopName.isNotEmpty ? _shopName : 'RentalHub',
        customerName: booking.customerName ?? 'Customer',
        customerId: booking.customerId,
        customerPhone: booking.customerPhone ?? '',
        cnicNumber: booking.customerCnic ?? 'Not provided',
        vehicleDetails: booking.vehicleName ?? 'Vehicle',
        packageType: booking.packageType,
        isWithDriver: booking.isWithDriver,
        pickupTime: booking.pickupTime,
        returnTime: booking.returnTime,
        totalAmount: booking.totalAmount,
        advancePaid: booking.advancePaid,
        securityDeposit: _securityDeposit,
        initialOdometer: odo,
        fuelLevel: _selectedFuel,
        damageNotes: _damageNotes,
        customerSignaturePng: customerPng,
        ownerSignaturePng: ownerPng,
        isOnline: true,
      );

      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(
          bookingId: booking.bookingId, status: 'active');

      if (mounted) {
        AppFeedback.showSuccess(context,
            'Handover certified! Digital A4 rental contract generated.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OwnerContractView(
              booking: booking.copyWith(status: 'active'),
              odometer: odo,
              fuelLevel: _selectedFuel,
              pdfBytes: entity.agreementPdfB64 != null
                  ? base64Decode(entity.agreementPdfB64!)
                  : null,
              verificationUrl:
                  PdfContractGenerator.verificationUrlFor(booking.bookingId),
              customerSignaturePng: customerPng,
              ownerSignaturePng: ownerPng,
              securityDeposit: _securityDeposit,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Handover completion failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicle Handover & Inspection',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(
                      '#${widget.booking.bookingId} • ${widget.booking.vehicleName ?? "Vehicle"}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    FuelOdometerInputWidget(
                      odometerController: _odometerController,
                      selectedFuel: _selectedFuel,
                      onFuelSelected: (f) => setState(() => _selectedFuel = f),
                    ),
                    const SizedBox(height: 16),
                    HandoverDamageNotesEditor(
                      onChanged: (notes) =>
                          setState(() => _damageNotes = notes),
                    ),
                    const SizedBox(height: 16),
                    DualSignaturePadWidget(
                      customerController: _customerSig,
                      ownerController: _ownerSig,
                    ),
                    const SizedBox(height: 24),
                    DebouncedButton(
                      text: _isSaving
                          ? 'Issuing Digital Contract...'
                          : 'Certify Handover & Generate Contract',
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
