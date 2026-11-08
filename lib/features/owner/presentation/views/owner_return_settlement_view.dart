import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/utils/settlement_calculator.dart';
import '../services/return_settlement_service.dart';
import '../widgets/handover_damage_notes_editor.dart';
import '../widgets/handover_notes_banner.dart';
import '../widgets/operations/fuel_odometer_input_widget.dart';
import '../widgets/operations/settlement_summary_receipt_widget.dart';
import 'owner_customer_rating_view.dart';

/// Phase B (F1/F2): the return inspection settles against real
/// numbers — the booking's km limit, the vehicle's per-km and
/// per-hour rates, the deposit actually held — and writes the
/// settlement into `security_deposits`. The old view settled against
/// hardcoded defaults (250 km, Rs. 15,000, Rs. 25/km) and recorded
/// nothing, so the money trail did not exist.
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

  int _initialOdometer = 45200;
  int _kmAllowance = 250;
  int _deposit = 0;
  int _extraKmPkr = 100;
  int _extraHourPkr = 0;

  @override
  void initState() {
    super.initState();
    _initialOdometer = widget.initialOdometer;
    _kmAllowance = widget.booking.kmLimit ?? widget.kmAllowance;
    _deposit = widget.initialDeposit;
    _returnOdometerController =
        TextEditingController(text: '$_initialOdometer');
    _returnOdometerController.addListener(() => setState(() {}));
    _loadRealValues();
  }

  Future<void> _loadRealValues() async {
    final values = await ReturnSettlementService.loadRealValues(
      widget.booking,
      fallbackOdometer: widget.initialOdometer,
      fallbackDeposit: widget.initialDeposit,
    );
    if (!mounted) return;
    setState(() {
      _initialOdometer = values.initialOdometer;
      _handoverDamageNotes = values.handoverDamageNotes;
      _extraKmPkr = values.extraKmPkr;
      _extraHourPkr = values.extraHourPkr;
      _deposit = values.deposit;
      _returnOdometerController.text = '$_initialOdometer';
    });
  }

  @override
  void dispose() {
    _returnOdometerController.dispose();
    _damageChargeController.dispose();
    super.dispose();
  }

  int get _returnOdometer =>
      int.tryParse(_returnOdometerController.text.trim()) ??
      _initialOdometer;
  int get _totalKmDriven => (_returnOdometer - _initialOdometer).clamp(0, 99999);
  int get _damageCharge => int.tryParse(_damageChargeController.text.trim()) ?? 0;
  int get _overtimeHours {
    final late = DateTime.now().difference(widget.booking.returnTime);
    return late.isNegative ? 0 : (late.inMinutes / 60).ceil();
  }

  SettlementBreakdown get _breakdown => SettlementCalculator.calculate(
        totalKmDriven: _totalKmDriven,
        kmAllowance: _kmAllowance,
        extraKmPkr: _extraKmPkr,
        fuelLevel: _returnFuel,
        damageCharge: _damageCharge,
        overtimeHours: _overtimeHours,
        extraHourPkr: _extraHourPkr,
        securityDeposit: _deposit,
      );

  Future<void> _finalizeReturn() async {
  final l10n = AppLocalizations.of(context)!;
    if (_returnOdometer < _initialOdometer) {
      AppFeedback.showError(context, l10n.returnOdometerBelow(_initialOdometer));
      return;
    }
    setState(() => _isFinalizing = true);
    try {
      final breakdown = await ReturnSettlementService.finalizeReturn(
        booking: widget.booking,
        returnOdometer: _returnOdometer,
        initialOdometer: _initialOdometer,
        kmAllowance: _kmAllowance,
        extraKmPkr: _extraKmPkr,
        extraHourPkr: _extraHourPkr,
        deposit: _deposit,
        fuelLevel: _returnFuel,
        returnDamageNotes: _returnDamageNotes,
        damageCharge: _damageCharge,
      );
      if (mounted) {
        AppFeedback.showSuccess(context,
            l10n.returnSettled(breakdown.netRefund));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OwnerCustomerRatingView(
              booking: widget.booking.copyWith(status: 'completed'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.returnFinalizeFailed(e.toString()));
      }
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
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.returnTitle,
              subtitle: l10n.returnTripAudit(widget.booking.bookingId),
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    FuelOdometerInputWidget(
                      title: l10n.returnTelemetryTitle,
                      odometerController: _returnOdometerController,
                      selectedFuel: _returnFuel,
                      onFuelSelected: (f) => setState(() => _returnFuel = f),
                    ),
                    if (_handoverDamageNotes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      HandoverNotesBanner(notes: _handoverDamageNotes),
                    ],
                    const SizedBox(height: 16),
                    HandoverDamageNotesEditor(
                      title: l10n.returnNewDamageTitle,
                      subtitle: l10n.returnNewDamageSubtitle,
                      onChanged: (notes) =>
                          setState(() => _returnDamageNotes = notes),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _damageChargeController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.returnDamageChargeLabel,
                        hintText: l10n.returnDamageChargeHint,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SettlementSummaryReceiptWidget(
                      totalKm: breakdown.totalKmDriven,
                      excessKm: breakdown.excessKm,
                      excessKmPenalty: breakdown.excessKmCharge,
                      extraKmRate: _extraKmPkr,
                      fuelDeficitFee: breakdown.fuelDeficit,
                      overtimeFee: breakdown.overtimeFee,
                      damageCharge: breakdown.damageCharge,
                      securityDeposit: _deposit,
                      netRefund: breakdown.netRefund,
                    ),
                    const SizedBox(height: 24),
                    DebouncedButton(
                      text: _isFinalizing
                          ? l10n.returnFinalizing
                          : l10n.returnFinalize,
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
