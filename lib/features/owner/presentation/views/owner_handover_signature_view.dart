import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:signature/signature.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/routing/route_names.dart';
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
import '../widgets/operations/exterior_photo_picker.dart';
import '../widgets/operations/fuel_odometer_input_widget.dart';
import '../widgets/operations/handover_balance_section.dart';
import '../widgets/operations/handover_checklist_section.dart';
import '../../../../core/theme/card_decoration.dart';

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

class _OwnerHandoverSignatureViewState extends State<OwnerHandoverSignatureView> {
  // Audit §13: the odometer starts EMPTY (hint text only) — a prefilled number would be certified as real if the owner never changed it.
  final _odometerController = TextEditingController();
  final _customerSig = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  final _ownerSig = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  String _selectedFuel = '';
  // PW-16: how the balance due was collected — null until the owner picks one; certify is blocked while it is null and a balance is due.
  String? _balanceMethod;
  List<String> _damageNotes = const [];
  bool _isSaving = false;
  bool _isLoadingShop = true;
  String? _loadError;
  String _shopName = '';
  int _securityDeposit = 0;
  // Audit item 4 (O19): exterior photos (side → signed URL), the documents/accessories checklist, and the keys toggle.
  Map<String, String?> _photos = const {'front': null, 'back': null, 'left': null, 'right': null};
  Set<String> _documentsGiven = {};
  Set<String> _accessories = {};
  bool _keysHandedOver = false;
  // Audit item 14 (O23): real vehicle detail for the agreement PDF.
  String? _vehiclePlate;
  String? _vehicleColour;
  String? _vehicleFuel;

  @override
  void initState() {
    super.initState();
    _shopName = widget.booking.shopName ?? '';
    _loadShopAndVehicle();
  }

  Future<void> _loadShopAndVehicle() async {
    // Audit C4: a failed shop/vehicle load shows a visible error with a retry — the shop name / deposit never silently fall back to 'RentalHub' / 0 without the owner knowing.
    setState(() { _isLoadingShop = true; _loadError = null; });
    String? error;
    try {
      final shopId = widget.booking.shopId;
      if (_shopName.isEmpty && shopId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
        final name = (doc.data()?['name'] ?? doc.data()?['shopName']) as String?;
        if (name != null && name.isNotEmpty && mounted) {
          setState(() => _shopName = name);
        }
      }
      final vehicles = await sl<FleetRemoteDataSource>().getShopVehicles(shopId);
      final vehicle = vehicles.where((v) => v.vehicleId == widget.booking.vehicleId).toList();
      if (vehicle.isNotEmpty && mounted) {
        setState(() { _securityDeposit = vehicle.first.securityDepositPkr ?? 0; _vehiclePlate = vehicle.first.plateNumber; _vehicleColour = vehicle.first.color; _vehicleFuel = vehicle.first.fuelType; });
      }
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    setState(() { _loadError = error; _isLoadingShop = false; });
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _customerSig.dispose();
    _ownerSig.dispose();
    super.dispose();
  }

  /// PW-16: the balance due at handover (total − advance paid), never negative. The deposit is separate and shown alongside it.
  int get _balanceDue => (widget.booking.totalAmount - widget.booking.advancePaid).clamp(0, 1 << 30);

  Future<void> _completeHandover() async {
  final l10n = AppLocalizations.of(context)!;
    final odo = int.tryParse(_odometerController.text.trim());
    if (odo == null || odo <= 0) {
      AppFeedback.showError(context, l10n.handoverOdometerInvalid);
      return;
    }

    // PW-17: fuel starts unselected — like the odometer, it must be explicitly picked; a preselected Full could be certified without the owner touching the control.
    if (_selectedFuel.isEmpty) {
      AppFeedback.showError(context, l10n.handoverFuelRequired);
      return;
    }

    // PW-16: block certifying while a balance due has no collection method recorded. An explicit 'Not yet' IS a recorded choice and passes — the balance is then visibly uncollected, not silently unrecorded.
    if (_balanceDue > 0 && _balanceMethod == null) {
      AppFeedback.showError(context, l10n.handoverBalanceMethodRequired);
      return;
    }

    if (_customerSig.isEmpty || _ownerSig.isEmpty) {
      AppFeedback.showError(context, l10n.handoverSignRequired);
      return;
    }

    // OW-m25: certifying with no shop name would print "RentalHub" on the agreement — block and let the owner retry the load (the banner above offers the retry).
    if (_shopName.isEmpty) { AppFeedback.showError(context, l10n.handoverShopNameRequired); return; }

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
        // Audit 2026-11-15 PW-16: first-class balance fields — the
        // cubit records them with the handover (offline queue +
        // agreement/handover docs), replacing the view's direct
        // Firestore merge onto the agreement doc.
        balanceDuePkr: _balanceDue, balancePaymentMethod: _balanceMethod,
        initialOdometer: odo, fuelLevel: _selectedFuel, damageNotes: _damageNotes,
        photoFrontUrl: _photos['front'], photoBackUrl: _photos['back'], photoLeftUrl: _photos['left'], photoRightUrl: _photos['right'],
        documentsGiven: _documentsGiven.toList(), accessories: _accessories.toList(), keysHandedOver: _keysHandedOver,
        vehiclePlate: _vehiclePlate, vehicleColour: _vehicleColour, vehicleFuel: _vehicleFuel,
        // Item 10 (O46–O48): guarantor identity for the PDF block.
        guarantorName: booking.guarantorName, guarantorCnic: booking.guarantorCnic, guarantorRelation: booking.guarantorRelation,
        customerSignaturePng: customerPng, ownerSignaturePng: ownerPng,
        // OW-m25: was hardcoded true — the offline queue would never have queued. Real connectivity now.
        isOnline: sl.isRegistered<ConnectivityService>() ? sl<ConnectivityService>().isOnline : true,
      );

      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(bookingId: booking.bookingId, status: 'active');

      if (mounted) {
        AppFeedback.showSuccess(context, l10n.handoverCertified);
        // Item 10 (O46–O48): handover completion lands on the
        // agreement wizard (preview → terms → share) instead of the
        // old Agreement Signed screen; that route stays reachable.
        context.pushReplacement(RouteNames.ownerAgreementWizard.replaceFirst(':id', booking.bookingId));
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
                      ExteriorPhotoPicker(bookingId: widget.booking.bookingId, shopId: widget.booking.shopId, photos: _photos, onChanged: (photos) => setState(() => _photos = photos)),
                      const SizedBox(height: 16),
                      HandoverChecklistSection(documentsGiven: _documentsGiven, accessories: _accessories, keysHandedOver: _keysHandedOver, onDocumentsChanged: (v) => setState(() => _documentsGiven = v), onAccessoriesChanged: (v) => setState(() => _accessories = v), onKeysChanged: (v) => setState(() => _keysHandedOver = v)),
                      const SizedBox(height: 16),
                      HandoverDamageNotesEditor(onChanged: (notes) => setState(() => _damageNotes = notes)),
                      const SizedBox(height: 16),
                      // PW-16/PW-17: balance + deposit rows sit ABOVE the signature pads — the money is visible before the owner certifies.
                      HandoverBalanceSection(balanceDue: _balanceDue, securityDeposit: _securityDeposit, selectedMethod: _balanceMethod, onMethodChanged: (m) => setState(() => _balanceMethod = m)),
                      const SizedBox(height: 16),
                      DualSignaturePadWidget(customerController: _customerSig, ownerController: _ownerSig),
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
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: AppCardDecoration.shadow(context)),
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
  // PW-16/PW-17: the deposit row now lives in HandoverBalanceSection (with the balance row), rendered above the signature pads.
}
