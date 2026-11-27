import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../widgets/fare_table_out_city_header.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';

/// Audit §5 (O09): the fare table — the read-only price list for one
/// vehicle, in In-City / Out-City / Hourly / Monthly tabs. Every row
/// is one of the vehicle's real packages (or the real out-of-city
/// rate, scaled from the packages the same way the booking picker
/// scales them); there are no invented fare rows. "Proceed" opens the
/// rate matrix; the banner states the default free delivery.
class OwnerFareTableView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  const OwnerFareTableView({
    super.key,
    required this.vehicle,
    this.onBack,
  });

  @override
  State<OwnerFareTableView> createState() => _OwnerFareTableViewState();
}

class _OwnerFareTableViewState extends State<OwnerFareTableView> {
  int _tab = 0;

  /// 09b §2: the vehicle's fixed route (resolved from its stored id)
  /// so the Out-City tab can show the route and its flat price.
  FixedRouteEntity? _fixedRoute;
  bool _loadingRoute = false;
  // OW-m16: a failed route load used to clear the spinner with no
  // error state at all.
  bool _routeFailed = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    if (v.outCityMode == 'fixedRoute' && v.outCityFixedRouteId != null) {
      _loadFixedRoute(v);
    }
  }

  Future<void> _loadFixedRoute(VehicleEntity v) async {
    if (!sl.isRegistered<GetShopFixedRoutesUseCase>()) return;
    setState(() {
      _loadingRoute = true;
      _routeFailed = false;
    });
    try {
      final routes = await sl<GetShopFixedRoutesUseCase>()(v.shopId);
      if (!mounted) return;
      FixedRouteEntity? match;
      for (final r in routes) {
        if (r.routeId == v.outCityFixedRouteId) match = r;
      }
      setState(() { _fixedRoute = match; _loadingRoute = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingRoute = false;
          _routeFailed = true;
        });
      }
    }
  }

  static String _packageTitle(AppLocalizations l10n, String label) => {'1h': l10n.pricingPackage1h, '3h': l10n.pricingPackage3h, '6h': l10n.pricingPackage6h, '12h': l10n.pricingPackage12h, '24h': l10n.pricingPackage24h, 'Weekly': l10n.pricingPackageWeekly, 'Monthly': l10n.pricingPackageMonthly}[label] ?? label;

  List<VehiclePackageEntity> _rowsForTab() {
    final packages = widget.vehicle.effectivePackages;
    switch (_tab) {
      case 1:
        // Out-City (09b §2): Fixed-route trips cost the route's flat
        // price whatever the package; Per-km trips cost the estimate
        // (rate × km/day × hours/24) with the estimated km as the
        // allowance; Per-day keeps the out-of-city ratio scaling.
        final v = widget.vehicle;
        if (v.outCityMode == 'fixedRoute' && _fixedRoute != null) {
          final route = _fixedRoute!;
          return packages.map((p) => p.copyWith(pricePkr: route.fixedPricePkr, kmIncluded: route.distanceKm)).toList();
        }
        if (v.outCityMode == 'perKm' && (v.outCityPerKmPkr ?? 0) > 0) {
          final rate = v.outCityPerKmPkr!;
          final kmPerDay = v.outOfCityKmPerDay ?? kDefaultOutCityKmPerDay;
          return packages.map((p) => p.copyWith(pricePkr: (rate * kmPerDay * p.hours / 24).round(), kmIncluded: (kmPerDay * p.hours / 24).round())).toList();
        }
        final daily = widget.vehicle.rates.daily24;
        final outDaily = widget.vehicle.rates.outOfCityDaily ?? daily;
        final ratio = daily > 0 ? outDaily / daily : 1.0;
        return packages.map((p) => p.copyWith(pricePkr: (p.pricePkr * ratio).round())).toList();
      case 2:
        return packages.where((p) => p.hours <= 12).toList();
      case 3:
        return packages.where((p) => p.label == 'Monthly' || p.label == 'Weekly').toList();
      default:
        return packages;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = widget.vehicle;
    final tabs = [l10n.fareTabInCity, l10n.fareTabOutCity, l10n.fareTabHourly, l10n.fareTabMonthly];
    final rows = _rowsForTab();
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.fareTableTitle,
              subtitle: v.displayName,
              onBack: widget.onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The deck's "Default Free delivery" banner.
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(l10n.fareFreeDelivery, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < tabs.length; i++)
                          ChoiceChip(
                            label: Text(tabs[i]),
                            selected: _tab == i,
                            onSelected: (_) => setState(() => _tab = i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_tab == 1) FareTableOutCityHeader(vehicle: v, fixedRoute: _fixedRoute, loadingRoute: _loadingRoute, routeFailed: _routeFailed, onRetryRoute: () => _loadFixedRoute(v)),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(l10n.fareNoRows, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      )
                    else
                      ...rows.map((p) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(_packageTitle(l10n, p.label), style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(l10n.fareKmIncluded(p.kmIncluded)),
                              trailing: Text(l10n.amountRs(formatRs(p.pricePkr)), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            ),
                          )),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.push(RouteNames.ownerPriceEstimate.replaceFirst(':vehicleId', v.vehicleId)),
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: Text(l10n.ratesViewEstimate),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
              child: DebouncedButton(
                text: l10n.fareProceed,
                icon: Icons.arrow_forward_rounded,
                onPressed: () async => context.push(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
