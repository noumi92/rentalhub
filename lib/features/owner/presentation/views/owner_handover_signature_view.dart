import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:signature/signature.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../handover/presentation/cubit/handover_cubit.dart';
import '../widgets/handover_damage_notes_editor.dart';
import '../widgets/operations/dual_signature_pad_widget.dart';
import '../widgets/operations/fuel_odometer_input_widget.dart';

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
  // Audit §13: the odometer starts EMPTY (hint text only) — a prefilled
  // number would be certified as real if the owner never changed it.
  final _odometerController = TextEditingController();
  final _customerSig = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  final _ownerSig = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  String _selectedFuel = '4/4 (Full)';
  List<String> _damageNotes = const [];
  bool _isSaving = false;
  bool _isLoadingShop = true;
  String? _loadError;
  String _shopName = '';
  int _securityDeposit = 0;

  @override
  void initState() {
    super.initState();
    _shopName = widget.booking.shopName ?? '';
    _loadShopAndVehicle();
  }

  Future<void> _loadShopAndVehicle() async {
    // Audit C4: a failed shop/vehicle load shows a visible error with a retry — the shop name / deposit never silently fall back to 'RentalHub' / 0 without the owner knowing.
    setState(() {
      _isLoadingShop = true;
      _loadError = null;
    });
    String? error;
    try {
      final shopId = widget.booking.shopId;
      if (_shopName.isEmpty && shopId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
        final name = (doc.data()?['name'] ?? doc.data()?['shopName']) as String?;
        if (name != null && name.isNotEmpty && mounted) setState(() => _shopName = name);
      }
      final vehicles = await sl<FleetRemoteDataSource>().getShopVehicles(shopId);
      final vehicle = vehicles.where((v) => v.vehicleId == widget.booking.vehicleId).toList();
      if (vehicle.isNotEmpty && mounted) setState(() => _securityDeposit = vehicle.first.securityDepositPkr ?? 0);
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _loadError = error;
      _isLoadingShop = false;
    });
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
      AppFeedback.showError(context, l10n.handoverSignRequired);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final customerPng = await _customerSig.toPngBytes();
      final ownerPng = await _ownerSig.toPngBytes();
      final booking = widget.booking;
      await sl<HandoverCubit>().completeHandoverOfflineFirst(
        bookingId: booking.bookingId, shopId: booking.shopId, shopName: _shopName.isNotEmpty ? _shopName : 'RentalHub',
        customerName: booking.customerName ?? l10n.requestsCustomerFallback, customerId: booking.customerId, customerPhone: booking.customerPhone ?? '',
        cnicNumber: booking.customerCnic ?? 'Not provided', vehicleDetails: booking.vehicleName ?? l10n.summaryVehicle, packageType: booking.packageType,
        isWithDriver: booking.isWithDriver, pickupTime: booking.pickupTime, returnTime: booking.returnTime,
        totalAmount: booking.totalAmount, advancePaid: booking.advancePaid, securityDeposit: _securityDeposit,
        initialOdometer: odo, fuelLevel: _selectedFuel, damageNotes: _damageNotes,
        customerSignaturePng: customerPng, ownerSignaturePng: ownerPng, isOnline: true,
      );

      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(bookingId: booking.bookingId, status: 'active');

      if (mounted) {
        AppFeedback.showSuccess(context, l10n.handoverCertified);
        // C11: route through go_router (the contract route loads the stored handover — PDF + signatures — by booking id).
        context.pushReplacement(RouteNames.ownerContract.replaceFirst(':id', booking.bookingId));
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.handoverCompleteFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            MinimalAppBar(title: l10n.handoverTitle, subtitle: '#${widget.booking.bookingId} • ${widget.booking.vehicleName ?? l10n.summaryVehicle}', onBack: widget.onBack),
            if (_isLoadingShop)
              const Expanded(child: AppLoadingState())
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                      if (_loadError != null) ...[
                        _loadErrorBanner(context, l10n),
                        const SizedBox(height: 16),
                      ],
                      FuelOdometerInputWidget(odometerController: _odometerController, selectedFuel: _selectedFuel, onFuelSelected: (f) => setState(() => _selectedFuel = f)),
                      const SizedBox(height: 16),
                      HandoverDamageNotesEditor(onChanged: (notes) => setState(() => _damageNotes = notes)),
                      const SizedBox(height: 16),
                      DualSignaturePadWidget(customerController: _customerSig, ownerController: _ownerSig),
                      const SizedBox(height: 16),
                      _depositRow(context, l10n),
                      const SizedBox(height: 24),
                      DebouncedButton(text: _isSaving ? l10n.handoverIssuing : l10n.handoverCertify, icon: Icons.assignment_turned_in_rounded, isLoading: _isSaving, onPressed: _completeHandover),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The shop/vehicle load failed: say so and offer a retry instead of silently certifying against the 'RentalHub' / Rs. 0 fallbacks.
  Widget _loadErrorBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.fleetLoadError(_loadError!), style: Theme.of(context).textTheme.bodySmall)),
          TextButton(onPressed: _loadShopAndVehicle, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }

  /// The already-loaded security deposit, surfaced before the owner certifies the handover (audit §13).
  Widget _depositRow(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(l10n.returnReceiptDepositHeld, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Text(l10n.amountRs(formatRs(_securityDeposit)), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
