import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:signature/signature.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
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
        final name =
            (doc.data()?['name'] ?? doc.data()?['shopName']) as String?;
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
  final l10n = AppLocalizations.of(context)!;
    final odo = int.tryParse(_odometerController.text.trim());
    if (odo == null || odo <= 0) {
      AppFeedback.showError(context, l10n.handoverOdometerInvalid);
      return;
    }

    if (_customerSig.isEmpty || _ownerSig.isEmpty) {
      AppFeedback.showError(context,
          l10n.handoverSignRequired);
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
        customerName: booking.customerName ?? l10n.requestsCustomerFallback,
        customerId: booking.customerId,
        customerPhone: booking.customerPhone ?? '',
        cnicNumber: booking.customerCnic ?? 'Not provided',
        vehicleDetails: booking.vehicleName ?? l10n.summaryVehicle,
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
            l10n.handoverCertified);
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
        AppFeedback.showError(context, l10n.handoverCompleteFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.handoverTitle,
              subtitle: '#${widget.booking.bookingId} • ${widget.booking.vehicleName ?? l10n.summaryVehicle}',
              onBack: widget.onBack,
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
                          ? l10n.handoverIssuing
                          : l10n.handoverCertify,
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
