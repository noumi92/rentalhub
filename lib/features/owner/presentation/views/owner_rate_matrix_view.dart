import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/update_vehicle_pricing_usecase.dart';
import '../constants/owner_vehicle_constants.dart';
import '../widgets/fleet/pricing_chrome.dart';
import '../widgets/fleet/pricing_drive_mode_card.dart';
import '../widgets/fleet/pricing_package_list.dart';
import '../widgets/fleet/pricing_policy_fields.dart';

/// Phase B (B2): the rate matrix now edits the vehicle's real packages
/// (price + on/off toggle per package, incl. 12h and Weekly), the
/// out-of-city rate, the with-driver surcharge, security deposit,
/// advance, extra-hour charge and fuel policy — and it actually saves
/// the drive-mode switches too (they used to be loaded but never
/// persisted). Everything saves in one write via
/// [UpdateVehiclePricingUseCase]; the legacy `rates` fields are kept
/// in sync so existing readers keep working.
/// Audit §6: every numeric field is validated before saving (an
/// unparseable field used to silently overwrite a real price with a
/// hardcoded default); back with unsaved edits asks first.
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
  late TextEditingController _outOfCityController, _surchargeController, _depositController, _advanceController, _extraHourController, _extraKmController, _outOfCityKmController;
  late bool _isSelfDrive, _isWithDriver;
  late String _fuelPolicy;
  bool _isSaving = false;
  late String _initialSnapshot;
  bool _discardConfirmed = false;

  // Audit §6: strict parse — no silent fallback to a hardcoded number.
  int? _priceOf(String label) => int.tryParse(_priceControllers[label]?.text.trim() ?? '');

  static String _packageTitle(AppLocalizations l10n, String label) => {'1h': l10n.pricingPackage1h, '3h': l10n.pricingPackage3h, '6h': l10n.pricingPackage6h, '12h': l10n.pricingPackage12h, '24h': l10n.pricingPackage24h, 'Weekly': l10n.pricingPackageWeekly}[label] ?? label;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _packages = List.of(v.effectivePackages);
    for (final p in _packages) {
      _priceControllers[p.label] = TextEditingController(text: p.pricePkr.toString());
    }
    _outOfCityController = TextEditingController(text: (v.rates.outOfCityDaily ?? (v.rates.daily24 * 1.3).round()).toString());
    _surchargeController = TextEditingController(text: (v.withDriverSurchargePkr ?? 2000).toString());
    _depositController = TextEditingController(text: (v.securityDepositPkr ?? 25000).toString());
    _advanceController = TextEditingController(text: (v.advanceRequiredPkr ?? 2000).toString());
    _extraHourController = TextEditingController(text: (v.extraHourPkr ?? 600).toString());
    _extraKmController = TextEditingController(text: (v.extraKmPkr ?? 100).toString());
    _outOfCityKmController = TextEditingController(text: (v.outOfCityKmPerDay ?? 350).toString());
    _isSelfDrive = v.isSelfDriveAvailable;
    _isWithDriver = v.isWithDriverAvailable;
    _fuelPolicy = v.fuelPolicy ?? 'Same to Same';
    _initialSnapshot = _snapshot();
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    _outOfCityController.dispose();
    _surchargeController.dispose();
    _depositController.dispose();
    _advanceController.dispose();
    _extraHourController.dispose();
    _extraKmController.dispose();
    _outOfCityKmController.dispose();
    super.dispose();
  }

  /// One string capturing every editable value, for the dirty check.
  String _snapshot() => [..._priceControllers.values.map((c) => c.text), _outOfCityController.text, _surchargeController.text, _depositController.text, _advanceController.text, _extraHourController.text, _extraKmController.text, _outOfCityKmController.text, '$_isSelfDrive', '$_isWithDriver', _fuelPolicy, ..._packages.map((p) => '${p.label}:${p.enabled}')].join('|');

  bool get _isDirty => _snapshot() != _initialSnapshot;

  void _pop() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
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
      if (p.enabled && bad(_packageTitle(l10n, p.label), _priceControllers[p.label]?.text)) return false;
    }
    if (bad(l10n.pricingOutOfCityDaily, _outOfCityController.text)) return false;
    if (bad(l10n.pricingWithDriverSurcharge, _surchargeController.text)) return false;
    if (bad(l10n.pricingSecurityDeposit, _depositController.text, allowZero: true)) return false;
    if (bad(l10n.pricingAdvanceRequired, _advanceController.text, allowZero: true)) return false;
    if (bad(l10n.pricingExtraHourCharge, _extraHourController.text)) return false;
    if (bad(l10n.pricingExtraKmCharge, _extraKmController.text)) return false;
    if (bad(l10n.pricingOutOfCityKmAllowance, _outOfCityKmController.text)) return false;
    return true;
  }

  Future<void> _saveRates() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validateAll()) return;
    setState(() => _isSaving = true);
    try {
      // Disabled packages keep their last price (never a default).
      final updatedPackages = _packages.map((p) => p.copyWith(pricePkr: _priceOf(p.label) ?? p.pricePkr)).toList();
      final r = widget.vehicle.rates;
      final updated = widget.vehicle.copyWith(
        packages: updatedPackages,
        rates: VehicleRatesEntity(hourly1: _priceOf('1h') ?? r.hourly1, hourly3: _priceOf('3h') ?? r.hourly3, hourly6: _priceOf('6h') ?? r.hourly6, daily24: _priceOf('24h') ?? r.daily24, outOfCityDaily: int.parse(_outOfCityController.text.trim())),
        weeklyRate: _priceOf('Weekly') ?? widget.vehicle.weeklyRate,
        isSelfDriveAvailable: _isSelfDrive, isWithDriverAvailable: _isWithDriver,
        withDriverSurchargePkr: int.parse(_surchargeController.text.trim()),
        securityDepositPkr: int.parse(_depositController.text.trim()),
        advanceRequiredPkr: int.parse(_advanceController.text.trim()),
        extraHourPkr: int.parse(_extraHourController.text.trim()),
        extraKmPkr: int.parse(_extraKmController.text.trim()),
        outOfCityKmPerDay: int.parse(_outOfCityKmController.text.trim()),
        fuelPolicy: _fuelPolicy,
      );
      await sl<UpdateVehiclePricingUseCase>()(vehicleId: widget.vehicle.vehicleId, vehicle: updated);
      if (mounted) {
        // The saved values are the new clean state — back no longer asks.
        _initialSnapshot = _snapshot();
        AppFeedback.showSuccess(context, l10n.pricingSavedSuccess);
        widget.onRatesSaved?.call();
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.pricingSaveFailed('$e'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = widget.vehicle;
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
              PricingHeader(vehicle: v, onBack: _handleBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.pricingDriveModeAvailability, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      PricingDriveModeCard(isSelfDrive: _isSelfDrive, onSelfDriveChanged: (val) => setState(() => _isSelfDrive = val), isWithDriver: _isWithDriver, onWithDriverChanged: (val) => setState(() => _isWithDriver = val)),
                      const SizedBox(height: 18),
                      Text(l10n.pricingRentalPackages, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(l10n.pricingPackagesHint, style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      PricingPackageList(
                        packages: _packages,
                        onToggle: (label, val) => setState(() {
                          final i = _packages.indexWhere((p) => p.label == label);
                          if (i != -1) _packages[i] = _packages[i].copyWith(enabled: val);
                        }),
                        priceController: (label) => _priceControllers[label]!,
                      ),
                      const SizedBox(height: 18),
                      Text(l10n.pricingPolicyTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      PricingPolicyFields(outOfCityController: _outOfCityController, surchargeController: _surchargeController, depositController: _depositController, advanceController: _advanceController, extraHourController: _extraHourController, extraKmController: _extraKmController, outOfCityKmController: _outOfCityKmController, fuelPolicy: _fuelPolicy, onFuelPolicyChanged: (f) => setState(() => _fuelPolicy = f), fuelPolicies: OwnerVehicleConstants.fuelPolicies),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              PricingSaveBar(isSaving: _isSaving, onPressed: _saveRates),
            ],
          ),
        ),
      ),
    );
  }
}
