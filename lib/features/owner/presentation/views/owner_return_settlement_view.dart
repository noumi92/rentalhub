import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/routing/route_names.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/utils/settlement_calculator.dart';
import '../services/return_settlement_service.dart';
import '../widgets/handover_damage_notes_editor.dart';
import '../widgets/handover_notes_banner.dart';
import '../widgets/operations/exterior_photo_picker.dart';
import '../widgets/operations/fuel_odometer_input_widget.dart';
import '../widgets/operations/return_fare_payment_section.dart';
import '../widgets/operations/return_inspection_sections.dart';
import '../widgets/operations/return_payment_steps.dart';
import '../widgets/operations/settlement_summary_receipt_widget.dart';
import '../../../../core/utils/money_format.dart';

/// Phase B (F1/F2): the return inspection settles against real numbers — the booking's km limit, the vehicle's per-km and per-hour rates, the deposit actually held — and writes the settlement into `security_deposits`.
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
  State<OwnerReturnSettlementView> createState() =>
      _OwnerReturnSettlementViewState();
}

class _OwnerReturnSettlementViewState extends State<OwnerReturnSettlementView> {
  late final TextEditingController _returnOdometerController;
  final _damageChargeController = TextEditingController();
  String _returnFuel = '4/4 (Full)';
  List<String> _returnDamageNotes = const [];
  List<String> _handoverDamageNotes = const [];
  bool _isFinalizing = false;
  // Audit §14 (Critical): Finalize stays disabled until the real values have loaded, and the load never overwrites an odometer the owner has already typed — the old code settled against 45200 / 250 km / Rs. 15,000 fallbacks and clobbered typed input mid-edit.
  bool _valuesLoaded = false;
  bool _loadFailed = false;
  String? _loadError;
  bool _odometerTouched = false;
  bool _suppressOdometerListener = false;

  int _initialOdometer = 45200;
  int _kmAllowance = 250;
  int _deposit = 0;
  int _extraKmPkr = 100;
  int _extraHourPkr = 0;
  // Gap (c): vehicle per-km pricing (booking-snapshot fallback).
  PerKmPricing _perKmPricing = const PerKmPricing();
  // Audit item 5/18 (O25/O26): inspection condition, return photos,
  // and the remaining rent collected at return.
  String _condition = 'good';
  Map<String, String?> _returnPhotos = const {'front': null, 'back': null, 'left': null, 'right': null};
  ({int amount, String? method}) _collected = (amount: 0, method: null);
  int _deductibleDamage = 0;
  int _extraCharges = 0;

  @override
  void initState() {
    super.initState();
    _initialOdometer = widget.initialOdometer;
    _kmAllowance = widget.booking.kmLimit ?? widget.kmAllowance;
    _deposit = widget.initialDeposit;
    // Starts EMPTY: no invented odometer is ever shown or settled.
    _returnOdometerController = TextEditingController();
    _returnOdometerController.addListener(() {
      if (!_suppressOdometerListener) _odometerTouched = true;
      setState(() {});
    });
    _loadRealValues();
  }

  Future<void> _loadRealValues() async {
    setState(() {
      _loadFailed = false;
      _loadError = null;
    });
    try {
      final values = await ReturnSettlementService.loadRealValues(widget.booking, fallbackOdometer: widget.initialOdometer, fallbackDeposit: widget.initialDeposit);
      if (!mounted) return;
      // Load once into the form only if the owner has not typed yet — done outside setState so the controller listener cannot fire a nested setState.
      if (!_odometerTouched) {
        _suppressOdometerListener = true;
        _returnOdometerController.text = '${values.initialOdometer}';
        _suppressOdometerListener = false;
      }
      setState(() {
        _initialOdometer = values.initialOdometer;
        _handoverDamageNotes = values.handoverDamageNotes;
        _extraKmPkr = values.extraKmPkr;
        _extraHourPkr = values.extraHourPkr;
        _perKmPricing = values.perKmPricing;
        _deposit = values.deposit;
        _deductibleDamage = values.deductibleDamage;
        _extraCharges = values.extraCharges;
        _valuesLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _returnOdometerController.dispose();
    _damageChargeController.dispose();
    super.dispose();
  }

  // OW-m24: nullable — an empty/unparseable reading is missing data, not "no kilometres driven"; Finalize blocks on it. The receipt breakdown keeps the initial-reading fallback so the summary still renders while the field is empty.
  int? get _returnOdometer => int.tryParse(_returnOdometerController.text.trim());
  int get _totalKmDriven => ((_returnOdometer ?? _initialOdometer) - _initialOdometer).clamp(0, 99999);
  // Damage charge is clamped to >= 0: a negative charge must never increase the refund.
  int get _damageCharge => (int.tryParse(_damageChargeController.text.trim()) ?? 0).clamp(0, 999999999);
  int get _overtimeHours {
    final late = DateTime.now().difference(widget.booking.returnTime);
    return late.isNegative ? 0 : (late.inMinutes / 60).ceil();
  }

  SettlementBreakdown get _breakdown => SettlementCalculator.calculate(
        totalKmDriven: _totalKmDriven, kmAllowance: _kmAllowance, extraKmPkr: _perKm != null ? 0 : _extraKmPkr, fuelLevel: _returnFuel,
        damageCharge: _damageCharge + _deductibleDamage, overtimeHours: _overtimeHours, extraHourPkr: _extraHourPkr, securityDeposit: _deposit,
        extraCharges: _extraCharges,
      );

  // Gap (c): the live per-km reconciliation; null for non-per-km bookings.
  PerKmSettlement? get _perKm => ReturnSettlementService.perKmSettlementFor(booking: widget.booking, totalKmDriven: _totalKmDriven, pricing: _perKmPricing);

  void _onDamageChargeChanged(String value) {
    // Keep the field and the receipt consistent: a negative charge is reset to 0 as soon as it is typed.
    final parsed = int.tryParse(value.trim());
    if (parsed != null && parsed < 0) {
      _damageChargeController.text = '0';
      _damageChargeController.selection = const TextSelection.collapsed(offset: 1);
    }
    setState(() {});
  }

  Future<void> _finalizeReturn() async {
  final l10n = AppLocalizations.of(context)!;
    // Belt-and-braces: the button is only rendered once loaded, but a stray call must never settle against unloaded values.
    if (!_valuesLoaded || _isFinalizing) return;
    if (_returnOdometer == null) { AppFeedback.showError(context, l10n.returnOdometerInvalid); return; }
    if (_returnOdometer! < _initialOdometer) { AppFeedback.showError(context, l10n.returnOdometerBelow(_initialOdometer)); return; }
    setState(() => _isFinalizing = true);
    try {
      final breakdown = await ReturnSettlementService.finalizeReturn(
        booking: widget.booking, returnOdometer: _returnOdometer!, initialOdometer: _initialOdometer, kmAllowance: _kmAllowance,
        extraKmPkr: _extraKmPkr, extraHourPkr: _extraHourPkr, deposit: _deposit, fuelLevel: _returnFuel,
        returnDamageNotes: _returnDamageNotes, damageCharge: _damageCharge,
        condition: _condition, returnPhotoUrls: _returnPhotos, deductibleDamage: _deductibleDamage, extraCharges: _extraCharges,
        remainingRentCollected: _collected.amount, paymentMethod: _collected.method, perKmSettlement: _perKm,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.returnSettled(formatRs(breakdown.netRefund)));
        // OW-m24: routed through go_router — the rate-customer route loads the booking itself (BookingRouteLoader), so the completed status is picked up from the settled record.
        context.pushReplacement(RouteNames.ownerRateCustomer.replaceFirst(':id', widget.booking.bookingId));
      }
    } catch (e) {
      // DS-13: the user sees a generic message; the raw error is
      // only logged for diagnostics, never shown.
      debugPrint('Return finalize failed: $e');
      if (mounted) AppFeedback.showError(context, l10n.returnFinalizeFailedGeneric);
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final breakdown = _breakdown;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: l10n.returnTitle, subtitle: l10n.returnTripAudit(widget.booking.bookingId), onBack: widget.onBack),
            if (!_valuesLoaded && !_loadFailed)
              const Expanded(child: AppLoadingState())
            else if (_loadFailed)
              Expanded(child: AppErrorState(message: l10n.fleetLoadError(_loadError ?? ''), onRetry: _loadRealValues))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                    // Finish build (O25): the landing moved to its own route (/owner/return-landing/:id) — this view now starts directly at the inspection.
                    ReturnConditionSelector(bookingId: widget.booking.bookingId, condition: _condition, onChanged: (c) => setState(() => _condition = c)),
                      const SizedBox(height: 16),
                      ExteriorPhotoPicker(bookingId: widget.booking.bookingId, shopId: widget.booking.shopId, photos: _returnPhotos, targetCollection: 'return_settlements', onChanged: (photos) => setState(() => _returnPhotos = photos)),
                      const SizedBox(height: 16),
                      FuelOdometerInputWidget(title: l10n.returnTelemetryTitle, odometerController: _returnOdometerController, selectedFuel: _returnFuel, onFuelSelected: (f) => setState(() => _returnFuel = f)),
                      if (_handoverDamageNotes.isNotEmpty) ...[const SizedBox(height: 12), HandoverNotesBanner(notes: _handoverDamageNotes)],
                      const SizedBox(height: 16),
                      HandoverDamageNotesEditor(title: l10n.returnNewDamageTitle, subtitle: l10n.returnNewDamageSubtitle, onChanged: (notes) => setState(() => _returnDamageNotes = notes)),
                      const SizedBox(height: 12),
                      TextField(controller: _damageChargeController, keyboardType: TextInputType.number, onChanged: _onDamageChargeChanged, decoration: InputDecoration(labelText: l10n.returnDamageChargeLabel, hintText: l10n.returnDamageChargeHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest)),
                      const SizedBox(height: 16),
                      ReturnFarePaymentSection(booking: widget.booking, onCollected: (amount, method) => setState(() => _collected = (amount: amount, method: method))),
                      const SizedBox(height: 16),
                      SettlementSummaryReceiptWidget(totalKm: breakdown.totalKmDriven, excessKm: breakdown.excessKm, excessKmPenalty: breakdown.excessKmCharge, extraKmRate: _extraKmPkr, fuelDeficitFee: breakdown.fuelDeficit, overtimeFee: breakdown.overtimeFee, damageCharge: breakdown.damageCharge, extraCharges: breakdown.extraCharges, securityDeposit: _deposit, netRefund: breakdown.netRefund, perKm: _perKm, amountOwed: breakdown.amountOwed),
                      const SizedBox(height: 24),
                      // Finish build (O26): refund first, then close — the steps widget owns the refund record; close still runs _finalizeReturn below.
                      ReturnPaymentSteps(bookingId: widget.booking.bookingId, netRefund: breakdown.netRefund, amountOwed: breakdown.amountOwed, isFinalizing: _isFinalizing, onCompleteClose: _finalizeReturn),
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
