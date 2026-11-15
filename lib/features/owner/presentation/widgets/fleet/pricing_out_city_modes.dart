import 'package:flutter/material.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import 'pricing_out_city_rates.dart';
import 'rate_matrix_field_widget.dart';

/// 09b §2 out-of-city pricing modes (deck p.4): how out-of-city
/// trips are priced for this vehicle — Per day (today's fields
/// unchanged: daily rate, km allowance, extra-km charge, driver
/// allowance), Per km (a Rs/km rate; the km allowance and the
/// extra-km charge do not apply because the base price IS per km)
/// or Fixed route (one flat price for a chosen fixed route; the
/// daily rate, km allowance and extra-km charge do not apply).
/// The mode pills are a [SegmentedButton], not [ChoiceChip]s, so the
/// package-chip count the 09b tests assert stays at seven.
/// Extracted so [OwnerRateMatrixView] stays under the 250-line cap:
/// this widget owns the route load (via [GetShopFixedRoutesUseCase],
/// in-memory seeded routes in tests) and reports the chosen route id
/// through [onRouteChanged]; the view only holds the selection.
class PricingOutCityModes extends StatefulWidget {
  const PricingOutCityModes({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.outOfCityController,
    required this.perKmController,
    required this.extraKmController,
    required this.outOfCityKmController,
    required this.perKmEnabled,
    required this.onPerKmChanged,
    required this.shopId,
    required this.selectedRouteId,
    required this.onRouteChanged,
  });

  /// 'perDay' | 'perKm' | 'fixedRoute'.
  final String mode;
  final ValueChanged<String> onModeChanged;
  final TextEditingController outOfCityController;
  final TextEditingController perKmController;
  final TextEditingController extraKmController;
  final TextEditingController outOfCityKmController;
  final bool perKmEnabled;
  final ValueChanged<bool> onPerKmChanged;
  final String shopId;
  final String? selectedRouteId;
  final ValueChanged<String?> onRouteChanged;

  @override
  State<PricingOutCityModes> createState() => _PricingOutCityModesState();
}

class _PricingOutCityModesState extends State<PricingOutCityModes> {
  List<FixedRouteEntity> _routes = [];
  bool _loadingRoutes = false, _routesFailed = false, _routesLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'fixedRoute') _loadRoutes();
  }

  @override
  void didUpdateWidget(covariant PricingOutCityModes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode == 'fixedRoute' && !_routesLoaded && !_loadingRoutes) _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    if (!sl.isRegistered<GetShopFixedRoutesUseCase>()) {
      if (mounted) setState(() => _routesFailed = true);
      return;
    }
    // OW-m6: retry must clear the failure flag first.
    setState(() {
      _loadingRoutes = true;
      _routesFailed = false;
    });
    try {
      final routes = await sl<GetShopFixedRoutesUseCase>()(widget.shopId);
      if (!mounted) return;
      setState(() {
        _routes = routes.where((r) => r.enabled).toList();
        _loadingRoutes = false;
        _routesLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _routesFailed = true; _loadingRoutes = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mode = widget.mode;
    FixedRouteEntity? selectedRoute;
    for (final r in _routes) {
      if (r.routeId == widget.selectedRouteId) selectedRoute = r;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.outCityPricingMode, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'perDay', label: Text(l10n.outCityModePerDay)),
            ButtonSegment(value: 'perKm', label: Text(l10n.outCityModePerKm)),
            ButtonSegment(value: 'fixedRoute', label: Text(l10n.outCityModeFixedRoute)),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => widget.onModeChanged(selection.first),
        ),
        const SizedBox(height: 12),
        if (mode == 'perDay')
          PricingOutCityRates(outOfCityController: widget.outOfCityController, extraKmController: widget.extraKmController, outOfCityKmController: widget.outOfCityKmController, perKmEnabled: widget.perKmEnabled, onPerKmChanged: widget.onPerKmChanged)
        else if (mode == 'perKm') ...[
          // Audit 2026-11-15 DS-10: localized hint, no literal 'Rs.'.
          RateMatrixFieldWidget(controller: widget.perKmController, label: l10n.outCityPerKmRate, hint: l10n.farePerKmUnit(l10n.amountRs(formatRs(30))), kmCap: l10n.farePerKmUnit(l10n.amountRs(formatRs(int.tryParse(widget.perKmController.text.trim()) ?? 0)))),
          const SizedBox(height: 10),
          Text(l10n.farePerKmEstimate(int.tryParse(widget.outOfCityKmController.text.trim()) ?? kDefaultOutCityKmPerDay), style: Theme.of(context).textTheme.labelSmall),
        ] else ...[
          if (_loadingRoutes)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (_routesFailed)
            // OW-m6: the old bare text had no recovery — the shared
            // error state with retry.
            AppErrorState(message: l10n.fixedRoutesLoadError, onRetry: _loadRoutes)
          else if (_routes.isEmpty)
            Text(l10n.outCityFixedRouteNone, style: Theme.of(context).textTheme.bodyMedium)
          else ...[
            Text(l10n.outCityFixedRouteLabel, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  isExpanded: true,
                  value: selectedRoute?.routeId,
                  hint: Text(l10n.outCityFixedRouteChoose),
                  items: _routes.map((r) => DropdownMenuItem(value: r.routeId, child: Text(r.displayName))).toList(),
                  onChanged: (id) => widget.onRouteChanged(id),
                ),
              ),
            ),
            if (selectedRoute != null) ...[
              const SizedBox(height: 8),
              Text(l10n.fareFixedRoute(selectedRoute.displayName), style: Theme.of(context).textTheme.bodyMedium),
              Text(l10n.fixedRouteSummary(selectedRoute.distanceKm, formatRs(selectedRoute.fixedPricePkr)), style: Theme.of(context).textTheme.labelSmall),
            ],
          ],
        ],
      ],
    );
  }
}
