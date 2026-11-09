import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/money_format.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import 'operations/booking_fare_breakdown.dart';

/// The vehicle dropdown of the walk-in booking wizard. Extracted from
/// [OwnerManualBookingView] so the view stays under the 250-line cap.
class ManualBookingVehicleDropdown extends StatelessWidget {
  const ManualBookingVehicleDropdown({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onChanged,
  });

  final List<VehicleEntity> vehicles;
  final VehicleEntity? selectedVehicle;
  final ValueChanged<VehicleEntity?> onChanged;

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VehicleEntity>(
          dropdownColor: Theme.of(context).colorScheme.surface,
          isExpanded: true,
          value: selectedVehicle,
          hint: Text(l10n.manualBookingSelectVehicleHint),
          items: vehicles.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text('${v.make} ${v.model} (${v.year}) - ${v.plateNumber}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// The package selector of the walk-in booking wizard: one chip per
/// enabled package of the chosen vehicle, with the computed total
/// (package price + with-driver surcharge) shown below. Extracted from
/// [OwnerManualBookingView] so the view stays under the 250-line cap.
/// Phase B (B2): the counter total comes from the vehicle's package,
/// not from a typed number. Stateful only so it can load the shop's
/// fixed routes for a fixed-route vehicle (09b §2): when the trip is
/// out-of-city and the vehicle prices by fixed route, a route picker
/// appears and the chosen route drives the total.
class ManualBookingPackageSelector extends StatefulWidget {
  const ManualBookingPackageSelector({
    super.key,
    required this.vehicle,
    required this.selectedPackage,
    required this.onPackageChanged,
    required this.isWithDriver,
    required this.onDriverModeChanged,
    this.isOutOfCity = false,
    this.pickup,
    this.returnTime,
    this.selectedFixedRoute,
    this.onFixedRouteChanged,
  });

  final VehicleEntity? vehicle;
  final VehiclePackageEntity? selectedPackage;
  final ValueChanged<VehiclePackageEntity> onPackageChanged;
  final bool isWithDriver;
  final ValueChanged<bool> onDriverModeChanged;

  /// Audit §5 item 1: the trip type and the picked dates drive the
  /// displayed total, exactly as they drive the booked total.
  final bool isOutOfCity;
  final DateTime? pickup;
  final DateTime? returnTime;

  /// 09b §2: the fixed route chosen for this out-of-city trip, and
  /// the callback that reports a (de)selection to the wizard, which
  /// owns it and threads it into the confirm step's total.
  final FixedRouteEntity? selectedFixedRoute;
  final ValueChanged<FixedRouteEntity?>? onFixedRouteChanged;

  @override
  State<ManualBookingPackageSelector> createState() =>
      _ManualBookingPackageSelectorState();

  /// The single-unit price of a package: the package price (scaled
  /// by the out-of-city ratio when the trip leaves the city — the
  /// same ratio the customer picker applies in
  /// `PackageTierList.optionsFor`) plus the with-driver surcharge.
  /// [totalFor] multiplies this by days/weeks; [unitFor] is the
  /// per-day (or per-week) rate the fare summary shows.
  /// 09b §2 modes, out-of-city only: Per-km prices by the kilometre
  /// — the unit is the ESTIMATE for this package's duration, rate ×
  /// km/day (stored, default 300) × hours/24, so a 24h package
  /// estimates one full allowance; the final total settles on the
  /// actual km at return. Fixed-route prices at the chosen route's
  /// flat price (see [fixedRoute]); without a chosen route the
  /// per-day ratio is the fallback, never zero.
  static int unitFor({
    required VehicleEntity? vehicle,
    required VehiclePackageEntity? package,
    required bool isWithDriver,
    bool isOutOfCity = false,
    FixedRouteEntity? fixedRoute,
  }) {
    if (vehicle == null || package == null) return 0;
    var unit = package.pricePkr;
    if (isOutOfCity) {
      if (vehicle.outCityMode == 'fixedRoute' && fixedRoute != null) {
        unit = fixedRoute.fixedPricePkr;
      } else if (vehicle.outCityMode == 'perKm' &&
          (vehicle.outCityPerKmPkr ?? 0) > 0) {
        final kmPerDay = vehicle.outOfCityKmPerDay ?? kDefaultOutCityKmPerDay;
        unit = (vehicle.outCityPerKmPkr! * kmPerDay * package.hours / 24)
            .round();
      } else if (vehicle.rates.daily24 > 0) {
        final outDaily =
            vehicle.rates.outOfCityDaily ?? vehicle.rates.daily24;
        unit = (unit * outDaily / vehicle.rates.daily24).round();
      }
    }
    if (!isWithDriver) return unit;
    final perDay = vehicle.withDriverSurchargePkr ?? 0;
    final surcharge = package.hours >= 24
        ? perDay * (package.hours ~/ 24)
        : (perDay * package.hours / 24).round();
    return unit + surcharge;
  }

  /// The counter total for a package, shared with the view that creates
  /// the booking so the displayed total and the booked total never drift.
  /// Audit §5 item 1: with pickup/return dates the total is day-aware
  /// — a 24h package costs the unit price per day, a Weekly package
  /// per week; hourly packages stay a single unit. Without dates the
  /// old single-unit total is returned, so existing callers are
  /// unaffected. 09b §2: a fixed route is one flat trip price plus the
  /// driver surcharge per day — the route price is NEVER multiplied
  /// by days. A per-km total is the estimate days × km/day × rate
  /// (plus driver per day); the final total settles on actual km.
  static int totalFor({
    required VehicleEntity? vehicle,
    required VehiclePackageEntity? package,
    required bool isWithDriver,
    bool isOutOfCity = false,
    DateTime? pickup,
    DateTime? returnTime,
    FixedRouteEntity? fixedRoute,
  }) {
    final v = vehicle;
    if (isOutOfCity && v != null && v.outCityMode == 'fixedRoute' && fixedRoute != null) {
      if (pickup == null || returnTime == null) {
        return unitFor(
          vehicle: vehicle,
          package: package,
          isWithDriver: isWithDriver,
          isOutOfCity: isOutOfCity,
          fixedRoute: fixedRoute,
        );
      }
      final days = dayCountBetween(pickup, returnTime);
      final driver =
          isWithDriver ? (v.withDriverSurchargePkr ?? 0) * days : 0;
      // Night stay (010b): out-of-city with-driver trips add nights ×
      // the vehicle's per-night rate; 0 otherwise.
      return fixedRoute.fixedPricePkr +
          driver +
          nightStayTotalFor(
            vehicle: vehicle,
            isWithDriver: isWithDriver,
            isOutOfCity: isOutOfCity,
            pickup: pickup,
            returnTime: returnTime,
          );
    }
    final unit = unitFor(
      vehicle: vehicle,
      package: package,
      isWithDriver: isWithDriver,
      isOutOfCity: isOutOfCity,
      fixedRoute: fixedRoute,
    );
    if (unit == 0 || package == null || pickup == null || returnTime == null) {
      return unit;
    }
    final days = dayCountBetween(pickup, returnTime);
    final int base;
    if (package.label == '24h') {
      base = unit * days;
    } else if (package.label == 'Weekly') {
      base = unit * ((days + 6) ~/ 7);
    } else if (package.label == 'Monthly') {
      // Audit §5 (Monthly): one unit per 30-day block, like Weekly.
      base = unit * ((days + 29) ~/ 30);
    } else {
      base = unit;
    }
    // Night stay (010b): out-of-city with-driver trips add nights ×
    // the vehicle's per-night rate; 0 otherwise.
    return base +
        nightStayTotalFor(
          vehicle: vehicle,
          isWithDriver: isWithDriver,
          isOutOfCity: isOutOfCity,
          pickup: pickup,
          returnTime: returnTime,
        );
  }

  /// Phase B (D2): the return time follows the chosen package — a
  /// 6-hour package returns in 6 hours, a weekly one in 7 days.
  static DateTime returnTimeFor({
    required DateTime pickup,
    required VehiclePackageEntity package,
  }) {
    return pickup.add(Duration(hours: package.hours));
  }
}

class _ManualBookingPackageSelectorState
    extends State<ManualBookingPackageSelector> {
  List<FixedRouteEntity> _routes = [];
  bool _loadingRoutes = false, _routesFailed = false;
  String _routesKey = '';

  /// One key per package chip, so a tap can scroll the selected chip
  /// into view — the chips live in one horizontal row.
  final Map<String, GlobalKey> _chipKeys = {};

  /// Reports the pick and scrolls its chip into view.
  void _selectPackage(VehiclePackageEntity package) {
    widget.onPackageChanged(package);
    WidgetsBinding.instance.addPostFrameCallback((_) { final c = _chipKeys[package.label]?.currentContext; if (c != null) Scrollable.ensureVisible(c, alignment: 0.5, duration: const Duration(milliseconds: 250)); });
  }

  /// The load key: routes are (re)loaded only for a fixed-route
  /// vehicle on an out-of-city trip, and once per vehicle.
  String get _loadKey {
    final v = widget.vehicle;
    if (v == null || !widget.isOutOfCity || v.outCityMode != 'fixedRoute') {
      return '';
    }
    return '${v.vehicleId}|${v.shopId}';
  }

  @override
  void initState() {
    super.initState();
    _maybeLoadRoutes();
  }

  @override
  void didUpdateWidget(covariant ManualBookingPackageSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLoadRoutes();
  }

  void _maybeLoadRoutes() {
    final key = _loadKey;
    if (key.isEmpty || key == _routesKey) return;
    _routesKey = key;
    if (!sl.isRegistered<GetShopFixedRoutesUseCase>()) {
      setState(() => _routesFailed = true);
      return;
    }
    setState(() => _loadingRoutes = true);
    sl<GetShopFixedRoutesUseCase>()(widget.vehicle!.shopId).then((routes) {
      if (!mounted) return;
      setState(() {
        _routes = routes.where((r) => r.enabled).toList();
        _loadingRoutes = false;
      });
      // Default to the route the owner set on the vehicle (09b §2),
      // when the wizard has not chosen one yet for this trip.
      if (widget.selectedFixedRoute == null) {
        FixedRouteEntity? stored;
        for (final r in _routes) {
          if (r.routeId == widget.vehicle?.outCityFixedRouteId) stored = r;
        }
        if (stored != null) widget.onFixedRouteChanged?.call(stored);
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() { _routesFailed = true; _loadingRoutes = false; });
    });
  }

  int get _total => ManualBookingPackageSelector.totalFor(
        vehicle: widget.vehicle,
        package: widget.selectedPackage,
        isWithDriver: widget.isWithDriver,
        isOutOfCity: widget.isOutOfCity,
        pickup: widget.pickup,
        returnTime: widget.returnTime,
        fixedRoute: widget.selectedFixedRoute,
      );

  /// The per-km estimate note: estimated km for this trip (days ×
  /// km/day, one allowance when no dates are picked yet).
  String? get _perKmEstimateNote {
    final v = widget.vehicle;
    if (!widget.isOutOfCity || v?.outCityMode != 'perKm') return null;
    final rate = v?.outCityPerKmPkr ?? 0;
    if (rate <= 0) return null;
    final kmPerDay = v?.outOfCityKmPerDay ?? kDefaultOutCityKmPerDay;
    final days = widget.pickup != null && widget.returnTime != null
        ? dayCountBetween(widget.pickup!, widget.returnTime!)
        : 1;
    return AppLocalizations.of(context)!
        .farePerKmEstimate(days * kmPerDay);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vehicle = widget.vehicle;
    if (vehicle == null) {
      return Text(l10n.manualBookingSelectVehicleFirst,
          style: Theme.of(context).textTheme.bodySmall);
    }
    final packages = vehicle.enabledPackages;
    if (packages.isEmpty) {
      return Text(l10n.manualBookingNoPackages,
          style: Theme.of(context).textTheme.bodySmall);
    }
    final showRoutePicker =
        widget.isOutOfCity && vehicle.outCityMode == 'fixedRoute';
    final estimateNote = _perKmEstimateNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: packages.map((p) {
              final selected = widget.selectedPackage?.label == p.label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: _chipKeys.putIfAbsent(p.label, () => GlobalKey()),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  // C5: grouped amount via the String-typed {price}
                  // placeholder (rulebook §4.5).
                  label: Text(l10n.manualBookingPackageChip(p.label, formatRs(p.pricePkr))),
                  selected: selected,
                  selectedColor: AppColors.orangeFill,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                  onSelected: (_) => _selectPackage(p),
                ),
              );
            }).toList(),
          ),
        ),
        if (showRoutePicker) ...[
          const SizedBox(height: 12),
          Text(l10n.outCityFixedRouteLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          if (_loadingRoutes)
            const Center(child: CircularProgressIndicator())
          else if (_routesFailed)
            Text(l10n.fixedRoutesLoadError,
                style: Theme.of(context).textTheme.bodyMedium)
          else if (_routes.isEmpty)
            Text(l10n.outCityFixedRouteNone,
                style: Theme.of(context).textTheme.bodyMedium)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FixedRouteEntity>(
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  isExpanded: true,
                  value: _routes.contains(widget.selectedFixedRoute)
                      ? widget.selectedFixedRoute
                      : null,
                  hint: Text(l10n.outCityFixedRouteChoose),
                  items: _routes
                      .map((r) => DropdownMenuItem(
                          value: r, child: Text(r.displayName)))
                      .toList(),
                  onChanged: (r) => widget.onFixedRouteChanged?.call(r),
                ),
              ),
            ),
          if (widget.selectedFixedRoute != null) ...[
            const SizedBox(height: 6),
            Text(l10n.fareFixedRoute(widget.selectedFixedRoute!.displayName),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(
                l10n.fixedRouteSummary(widget.selectedFixedRoute!.distanceKm,
                    formatRs(widget.selectedFixedRoute!.fixedPricePkr)),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Text(l10n.withDriver,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            Switch(
              value: widget.isWithDriver,
              activeThumbColor: AppColors.secondary,
              onChanged: widget.onDriverModeChanged,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.manualBookingTotal(formatRs(_total)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
        if (estimateNote != null) ...[
          const SizedBox(height: 4),
          Text(estimateNote, style: Theme.of(context).textTheme.labelSmall),
        ],
      ],
    );
  }
}

/// Lightweight 3-step indicator for the walk-in booking wizard
/// (Customer / Vehicle+Package / Confirm). Display-only: the wizard
/// stays a single page; the indicator just shows where the owner is.
class ManualBookingStepIndicator extends StatelessWidget {
  const ManualBookingStepIndicator({super.key, required this.currentStep});

  /// 1-based step the owner is on (1..3).
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.manualBookingCustomerSection,
      l10n.manualBookingVehicleSection,
      l10n.manualBookingConfirmTitle,
    ];
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: i + 1 < currentStep
                      ? AppColors.accentSuccessStrong
                      : i + 1 == currentStep
                          ? AppColors.orangeFill
                          : colorScheme.surfaceContainerHighest,
                  child: i + 1 < currentStep
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: i + 1 == currentStep
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                              ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: i + 1 == currentStep
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: i + 1 == currentStep
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact load-failure card for the vehicle section: a visible error
/// with a retry, instead of the old silent empty dropdown (audit C4).
class ManualBookingLoadErrorCard extends StatelessWidget {
  const ManualBookingLoadErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.commonRetry),
          ),
        ],
      ),
    );
  }
}
