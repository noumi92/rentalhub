import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import '../../../fleet/domain/usecases/update_vehicle_pricing_usecase.dart';
import '../widgets/fleet/boundary_map_card.dart';
import '../widgets/fleet/pricing_chrome.dart';
import '../widgets/fleet/pricing_trip_charges.dart';

/// 010b "Out-of-city rules" (deck p.4): the CAR-LEVEL shared rules
/// applying to ALL packages — editable home-city boundary, the shop's
/// fixed routes, trip charges (fuel policy, deposit, advance, driver
/// night stay per night, tolls & parking). NO in-city pricing, NO
/// per-package fields and NO boundary map: the model has no fields
/// for them.
class OwnerOutCityRulesView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  const OwnerOutCityRulesView({super.key, required this.vehicle, this.onBack});

  @override
  State<OwnerOutCityRulesView> createState() => _OwnerOutCityRulesViewState();
}

class _OwnerOutCityRulesViewState extends State<OwnerOutCityRulesView> {
  late String _homeCity;
  late int _radiusKm;
  late String _fuelPolicy;
  late String _tollsPaidBy;
  late TextEditingController _depositController, _advanceController, _nightStayController;
  // Boundary dialog controllers live on the state (not per-dialog):
  // disposing them the moment the dialog pops races the pop
  // animation, which rebuilds the dialog's fields after dispose.
  late TextEditingController _boundaryCityController, _boundaryRadiusController;
  List<FixedRouteEntity> _routes = [];
  bool _loadingRoutes = true, _routesFailed = false, _isSaving = false, _discardConfirmed = false;
  late String _initialSnapshot;

  String _snapshot() => '$_homeCity|$_radiusKm|$_fuelPolicy|$_tollsPaidBy|${_depositController.text}|${_advanceController.text}|${_nightStayController.text}';
  bool get _isDirty => _snapshot() != _initialSnapshot;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    // Unset boundary reads as the deck's Lahore / 40 km defaults.
    _homeCity = v.homeCity ?? 'Lahore';
    _radiusKm = v.homeCityRadiusKm ?? 40;
    _fuelPolicy = v.fuelPolicy ?? 'Same to Same';
    _tollsPaidBy = v.tollsPaidBy ?? 'customer';
    _depositController = TextEditingController(text: (v.securityDepositPkr ?? 25000).toString());
    _advanceController = TextEditingController(text: (v.advanceRequiredPkr ?? 2000).toString());
    // Unset night stay reads as the deck default (Rs 2,000/night).
    _nightStayController = TextEditingController(text: (v.driverNightStayPkr ?? kDefaultDriverNightStayPkr).toString());
    _boundaryCityController = TextEditingController();
    _boundaryRadiusController = TextEditingController();
    _initialSnapshot = _snapshot();
    _loadRoutes();
  }

  @override
  void dispose() {
    _depositController.dispose();
    _advanceController.dispose();
    _nightStayController.dispose();
    _boundaryCityController.dispose();
    _boundaryRadiusController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    // OW-m6: retry must clear the failure flag first.
    if (mounted) setState(() {
      _loadingRoutes = true;
      _routesFailed = false;
    });
    try {
      final routes = await sl<GetShopFixedRoutesUseCase>()(widget.vehicle.shopId);
      if (!mounted) return;
      setState(() { _routes = routes; _loadingRoutes = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _routesFailed = true; _loadingRoutes = false; });
    }
  }

  void _pop() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

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
      setState(() => _discardConfirmed = true);
      _pop();
    }
  }

  /// The boundary edit: city + radius in a dialog. OK only applies
  /// to the form state — "Save rules" is what persists it.
  Future<void> _editBoundary() async {
    final l10n = AppLocalizations.of(context)!;
    _boundaryCityController.text = _homeCity;
    _boundaryRadiusController.text = _radiusKm.toString();
    final applied = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.outCityBoundaryTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _boundaryCityController, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: l10n.outCityBoundaryCity)),
          const SizedBox(height: 12),
          TextField(controller: _boundaryRadiusController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.outCityBoundaryRadius)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              final city = _boundaryCityController.text.trim();
              final radius = int.tryParse(_boundaryRadiusController.text.trim());
              if (city.isEmpty || radius == null || radius <= 0) {
                AppFeedback.showError(ctx, l10n.rateMatrixInvalidField(l10n.outCityBoundaryTitle));
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (applied == true && mounted) setState(() { _homeCity = _boundaryCityController.text.trim(); _radiusKm = int.parse(_boundaryRadiusController.text.trim()); });
  }

  Future<void> _saveRules() async {
    final l10n = AppLocalizations.of(context)!;
    final deposit = int.tryParse(_depositController.text.trim());
    final advance = int.tryParse(_advanceController.text.trim());
    final nightStay = int.tryParse(_nightStayController.text.trim());
    if (deposit == null || deposit < 0 || advance == null || advance < 0 || nightStay == null || nightStay < 0) {
      AppFeedback.showError(context, l10n.rateMatrixInvalidField(nightStay == null || nightStay < 0 ? l10n.outCityNightStay : deposit == null || deposit < 0 ? l10n.pricingSecurityDeposit : l10n.pricingAdvanceRequired));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = widget.vehicle.copyWith(homeCity: _homeCity, homeCityRadiusKm: _radiusKm, fuelPolicy: _fuelPolicy, securityDepositPkr: deposit, advanceRequiredPkr: advance, driverNightStayPkr: nightStay, tollsPaidBy: _tollsPaidBy);
      await sl<UpdateVehiclePricingUseCase>()(vehicleId: widget.vehicle.vehicleId, vehicle: updated);
      if (mounted) {
        _initialSnapshot = _snapshot();
        AppFeedback.showSuccess(context, l10n.outCityRulesSaved);
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
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isDirty || _discardConfirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              MinimalAppBar(title: l10n.outCityRulesTitle, subtitle: l10n.outCityRulesAppliesAll, onBack: _handleBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.outCityBoundaryTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      BoundaryMapCard(
                        shopId: widget.vehicle.shopId,
                        homeCity: _homeCity,
                        radiusKm: _radiusKm,
                        onEdit: _editBoundary,
                      ),
                      const SizedBox(height: 18),
                      Text(l10n.fixedRoutesTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(l10n.fixedRoutesSubtitle, style: theme.textTheme.labelSmall),
                      const SizedBox(height: 8),
                      if (_loadingRoutes)
                        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                      else if (_routesFailed)
                        // OW-m6: the old bare text had no recovery.
                        AppErrorState(message: l10n.fixedRoutesLoadError, onRetry: _loadRoutes)
                      else if (_routes.isEmpty)
                        Text(l10n.fixedRoutesEmpty, style: theme.textTheme.bodyMedium)
                      else
                        ..._routes.map((r) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.route_rounded), title: Text(r.displayName, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(l10n.fixedRouteSummary(r.distanceKm, formatRs(r.fixedPricePkr)))))),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(icon: const Icon(Icons.add_rounded, size: 18), label: Text(l10n.fixedRouteAddButton), onPressed: () => context.push(RouteNames.ownerFixedRoutes)),
                      const SizedBox(height: 18),
                      PricingTripCharges(
                        depositController: _depositController,
                        advanceController: _advanceController,
                        nightStayController: _nightStayController,
                        fuelPolicy: _fuelPolicy,
                        onFuelPolicyChanged: (f) => setState(() => _fuelPolicy = f),
                        tollsPaidBy: _tollsPaidBy,
                        onTollsChanged: (t) => setState(() => _tollsPaidBy = t),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              PricingSaveBar(isSaving: _isSaving, onPressed: _saveRules, label: l10n.outCityRulesSave),
            ],
          ),
        ),
      ),
    );
  }
}
