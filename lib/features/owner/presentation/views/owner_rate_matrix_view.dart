import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/update_vehicle_pricing_usecase.dart';
import '../widgets/fleet/pricing_chrome.dart';
import '../widgets/fleet/pricing_drive_mode_card.dart';
import '../widgets/fleet/pricing_out_city_modes.dart';
import '../widgets/fleet/rate_matrix_field_widget.dart';

/// 09b "Package Rates" (deck p.4): the SIMPLE per-package price editor.
/// One package at a time — seven package chips, the selected package's
/// price row, then the shared out-of-city values (labelled as applying
/// to all packages: the model stores ONE out-of-city daily rate, ONE
/// extra-km charge and ONE km allowance per vehicle, never per-package
/// prices). No per-package enable toggles, no custom-rates editor, no
/// "View estimate" link — those lived in the old complex matrix.
/// Everything saves in one write via [UpdateVehiclePricingUseCase];
/// the legacy `rates` fields are kept in sync so existing readers
/// keep working. Deposit / advance / fuel policy live on the
/// out-of-city rules screen (010b) now and are left untouched here.
/// Audit §6: every numeric field is validated before saving; back
/// with unsaved edits asks first.
class OwnerRateMatrixView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onRatesSaved;
  final VoidCallback? onBack;

  const OwnerRateMatrixView({super.key, required this.vehicle, this.onRatesSaved, this.onBack});

  @override
  State<OwnerRateMatrixView> createState() => _OwnerRateMatrixViewState();
}

class _OwnerRateMatrixViewState extends State<OwnerRateMatrixView> {
  late List<VehiclePackageEntity> _packages;
  final Map<String, TextEditingController> _priceControllers = {};
  String _selectedLabel = '24h';
  late TextEditingController _outOfCityController, _perKmController, _extraHourController, _extraKmController, _outOfCityKmController;
  late bool _isSelfDrive, _isWithDriver, _perKmEnabled;
  late String _outCityMode; late String? _selectedRouteId; final Map<String, GlobalKey> _chipKeys = {};
  bool _isSaving = false;
  late String _initialSnapshot;
  bool _discardConfirmed = false;

  // Audit §6: strict parse — no silent fallback to a hardcoded number.
  int? _priceOf(String label) => int.tryParse(_priceControllers[label]?.text.trim() ?? '');

  static String _packageTitle(AppLocalizations l10n, String label) => {'1h': l10n.pricingPackage1h, '3h': l10n.pricingPackage3h, '6h': l10n.pricingPackage6h, '12h': l10n.pricingPackage12h, '24h': l10n.pricingPackage24h, 'Weekly': l10n.pricingPackageWeekly, 'Monthly': l10n.pricingPackageMonthly}[label] ?? label;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _packages = List.of(v.effectivePackages);
    for (final p in _packages) { _priceControllers[p.label] = TextEditingController(text: p.pricePkr.toString()); _chipKeys[p.label] = GlobalKey(); }
    _outOfCityController = TextEditingController(text: (v.rates.outOfCityDaily ?? (v.rates.daily24 * 1.3).round()).toString());
    _perKmController = TextEditingController(text: (v.outCityPerKmPkr ?? 30).toString());
    _outCityMode = v.outCityMode ?? 'perDay'; _selectedRouteId = v.outCityFixedRouteId;
    _extraHourController = TextEditingController(text: (v.extraHourPkr ?? 600).toString());
    _extraKmController = TextEditingController(text: (v.extraKmPkr ?? 100).toString());
    _outOfCityKmController = TextEditingController(text: (v.outOfCityKmPerDay ?? kDefaultOutCityKmPerDay).toString());
    _isSelfDrive = v.isSelfDriveAvailable;
    _isWithDriver = v.isWithDriverAvailable;
    _perKmEnabled = v.perKmPricingEnabled;
    _initialSnapshot = _snapshot();
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    _outOfCityController.dispose(); _perKmController.dispose();
    _extraHourController.dispose();
    _extraKmController.dispose();
    _outOfCityKmController.dispose();
    super.dispose();
  }

  /// One string capturing every editable value, for the dirty check.
  /// The selected chip is UI state, not data — switching packages
  /// never marks the form dirty.
  String _snapshot() => [..._priceControllers.values.map((c) => c.text), _outOfCityController.text, _extraHourController.text, _extraKmController.text, _outOfCityKmController.text, '$_isSelfDrive', '$_isWithDriver', '$_perKmEnabled', _outCityMode, _perKmController.text, '$_selectedRouteId'].join('|');

  bool get _isDirty => _snapshot() != _initialSnapshot;

  void _pop() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  /// Selects a package and scrolls its chip into view (one horizontal row).
  void _selectPackage(String label) {
    setState(() => _selectedLabel = label); WidgetsBinding.instance.addPostFrameCallback((_) { final c = _chipKeys[label]?.currentContext; if (c != null) Scrollable.ensureVisible(c, alignment: 0.5, duration: const Duration(milliseconds: 250)); });
  }

  /// Audit §6 (C10): back with unsaved edits confirms first — edited prices are otherwise lost silently.
  Future<void> _handleBack() async {
    if (!_isDirty) return _pop();
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pricingUnsavedTitle),
        content: Text(l10n.pricingUnsavedBody),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.syncDiscard))],
      ),
    );
    if (discard == true) {
      // PopScope vetoes pops while dirty, so the confirmed discard must flip the gate before popping.
      setState(() => _discardConfirmed = true);
      _pop();
    }
  }

  /// Audit §6: validate ALL numeric fields before saving; on failure show WHICH field is invalid and do NOT save.
  bool _validateAll() {
    final l10n = AppLocalizations.of(context)!;
    bool bad(String label, String? text, {bool allowZero = false}) {
      final v = int.tryParse((text ?? '').trim());
      if (v == null || v < 0 || (!allowZero && v == 0)) {
        AppFeedback.showError(context, l10n.rateMatrixInvalidField(label));
        return true;
      }
      return false;
    }

    for (final p in _packages) {
      if (bad(_packageTitle(l10n, p.label), _priceControllers[p.label]?.text, allowZero: true)) return false; // OW-m3: Rs. 0 is a real (free) package price, not an error.
    }
    // 09b §2 modes: only the active mode's fields are validated — in Per-km mode the daily rate, km allowance and extra-km charge do not apply (the base price IS per km); in Fixed-route mode the flat route price replaces them, so a route must be selected. Audit §5 (P4-O07): no extra-km charge to validate when Per KM pricing is off — the field is disabled and keeps its last value.
    if (_outCityMode == 'perKm') { if (bad(l10n.outCityPerKmRate, _perKmController.text)) return false; }
    else if (_outCityMode == 'fixedRoute') { if (_selectedRouteId == null) { AppFeedback.showError(context, l10n.rateMatrixInvalidField(l10n.outCityFixedRouteLabel)); return false; } }
    else { if (bad(l10n.pricingOutOfCityDaily, _outOfCityController.text)) return false; if (_perKmEnabled && bad(l10n.pricingExtraKmCharge, _extraKmController.text)) return false; if (bad(l10n.pricingOutOfCityKmAllowance, _outOfCityKmController.text)) return false; }
    if (bad(l10n.pricingExtraHourCharge, _extraHourController.text)) return false;
    return true;
  }

  Future<void> _saveRates() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validateAll()) return;
    setState(() => _isSaving = true);
    try {
      // Enabled flags are preserved as stored — this screen has no toggles for them.
      final updatedPackages = _packages.map((p) => p.copyWith(pricePkr: _priceOf(p.label) ?? p.pricePkr)).toList();
      final r = widget.vehicle.rates;
      final updated = widget.vehicle.copyWith(
        packages: updatedPackages,
        rates: VehicleRatesEntity(hourly1: _priceOf('1h') ?? r.hourly1, hourly3: _priceOf('3h') ?? r.hourly3, hourly6: _priceOf('6h') ?? r.hourly6, daily24: _priceOf('24h') ?? r.daily24, outOfCityDaily: int.parse(_outOfCityController.text.trim())),
        weeklyRate: _priceOf('Weekly') ?? widget.vehicle.weeklyRate,
        monthlyRate: _priceOf('Monthly') ?? widget.vehicle.monthlyRate,
        isSelfDriveAvailable: _isSelfDrive, isWithDriverAvailable: _isWithDriver,
        extraHourPkr: int.parse(_extraHourController.text.trim()),
        extraKmPkr: int.parse(_extraKmController.text.trim()),
        outOfCityKmPerDay: int.parse(_outOfCityKmController.text.trim()),
        perKmPricingEnabled: _perKmEnabled,
        // 09b §2 modes: the mode's own value is saved; the other
        // modes' values pass through untouched (copyWith cannot clear
        // a field, and the fare path only reads the active mode's).
        outCityMode: _outCityMode, outCityPerKmPkr: _outCityMode == 'perKm' ? int.parse(_perKmController.text.trim()) : widget.vehicle.outCityPerKmPkr, outCityFixedRouteId: _outCityMode == 'fixedRoute' ? _selectedRouteId : widget.vehicle.outCityFixedRouteId,
        // Deposit / advance / fuel policy / custom rates are edited
        // elsewhere (010b / legacy data) — pass them through untouched.
        customRates: widget.vehicle.customRates,
      );
      await sl<UpdateVehiclePricingUseCase>()(vehicleId: widget.vehicle.vehicleId, vehicle: updated);
      if (mounted) {
        // The saved values are the new clean state — back no longer asks.
        _initialSnapshot = _snapshot();
        AppFeedback.showSuccess(context, l10n.carEditorSaved);
        widget.onRatesSaved?.call();
      }
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = widget.vehicle;
    final selected = _packages.firstWhere((p) => p.label == _selectedLabel, orElse: () => _packages.first);
    return PopScope(
      // Clean (or discard-confirmed) pops go through; a dirty pop is vetoed and routed to the confirm dialog instead.
      canPop: !_isDirty || _discardConfirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          // C1: MinimalAppBar owns the top inset.
          top: false,
          child: Column(
            children: [
              PricingHeader(vehicle: v, onBack: _handleBack, title: l10n.carEditorTitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.pricingDriveModeAvailability, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      PricingDriveModeCard(isSelfDrive: _isSelfDrive, onSelfDriveChanged: (val) => setState(() => _isSelfDrive = val), isWithDriver: _isWithDriver, onWithDriverChanged: (val) => setState(() => _isWithDriver = val)),
                      const SizedBox(height: 18),
                      Text(l10n.rateMatrixInCityTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      // 09b: pick ONE package, edit its price — one
                      // horizontal row of chips. All seven controllers
                      // live in initState, so switching never discards an edit.
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: _packages.map((p) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(key: _chipKeys[p.label], label: Text(_packageTitle(l10n, p.label)), selected: p.label == _selectedLabel, onSelected: (_) => _selectPackage(p.label)))).toList()),
                      ),
                      const SizedBox(height: 12),
                      RateMatrixFieldWidget(controller: _priceControllers[selected.label]!, label: _packageTitle(l10n, selected.label), hint: l10n.amountRs(formatRs(selected.pricePkr)), kmCap: l10n.pricingKmIncluded(selected.kmIncluded)),
                      const SizedBox(height: 10),
                      RateMatrixFieldWidget(controller: _extraHourController, label: l10n.pricingExtraHourCharge, hint: l10n.pricingHintPerHour(l10n.amountRs(formatRs(600))), kmCap: l10n.pricingExtraHourCap),
                      const SizedBox(height: 18),
                      Text(l10n.rateMatrixOutCityTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(l10n.outCityRulesAppliesAll, style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      PricingOutCityModes(mode: _outCityMode, onModeChanged: (m) => setState(() => _outCityMode = m), outOfCityController: _outOfCityController, perKmController: _perKmController, extraKmController: _extraKmController, outOfCityKmController: _outOfCityKmController, perKmEnabled: _perKmEnabled, onPerKmChanged: (val) => setState(() => _perKmEnabled = val), shopId: v.shopId, selectedRouteId: _selectedRouteId, onRouteChanged: (id) => setState(() => _selectedRouteId = id)),
                    ],
                  ),
                ),
              ),
              PricingSaveBar(isSaving: _isSaving, onPressed: _saveRates, label: l10n.carEditorSave),
            ],
          ),
        ),
      ),
    );
  }
}
