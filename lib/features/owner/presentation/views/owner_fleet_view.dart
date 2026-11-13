import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_icon_chip.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/cubit/fleet_state.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../widgets/fleet/fleet_helpers.dart';
import '../widgets/fleet/fleet_list_section.dart';
import '../widgets/fleet/fleet_rented_until.dart';
import '../widgets/fleet/fleet_filter_chips.dart';
import '../widgets/fleet/fleet_metrics_row.dart';
import '../widgets/fleet/fleet_quick_actions.dart';
import '../widgets/fleet/fleet_search_field.dart';
import '../services/subscription_data_source.dart';
import 'owner_subscription_limit_sheet.dart';

/// Phase B (B1): the fleet list now reads real vehicles through
/// [FleetCubit] (Firestore, with the in-memory fallback when offline)
/// instead of `MockDatabase.vehicles`. Status values are the entity's
/// lowercase ones ('available' | 'rented' | 'maintenance'). The
/// simplified card (2026-11-09) has only two actions: Rates opens the
/// per-vehicle rate matrix (Phase A route `/owner/rates/:vehicleId`)
/// and Out-of-city rules opens `/owner/out-city-rules/:vehicleId`.
class OwnerFleetView extends StatefulWidget {
  final String? shopId;
  final VoidCallback? onAddVehicle;
  const OwnerFleetView({super.key, this.shopId, this.onAddVehicle});

  @override
  State<OwnerFleetView> createState() => _OwnerFleetViewState();
}

class _OwnerFleetViewState extends State<OwnerFleetView> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  late final FleetCubit _cubit;

  /// RQ-F10: the active booking's return date per vehicle (same
  /// shop bookings the fleet calendar reads). Best-effort: a failed
  /// load leaves the map empty and the cards show no return line.
  Map<String, DateTime> _rentedUntil = {};

  String get _shopId => widget.shopId ?? currentShopId();

  // Phone bug: double-tap duplicate pushes are guarded by
  // PushOnceGuard (see fleet_helpers.dart).
  final _pushGuard = PushOnceGuard();

  Future<Object?> _pushOnce(String location) =>
      _pushGuard.push(context, location);

  @override
  void initState() {
    super.initState();
    _cubit = sl<FleetCubit>()..loadVehicles(_shopId);
    _loadRentedUntil();
  }

  Future<void> _loadRentedUntil() async {
    try {
      final map = await loadRentedUntilByVehicle(
          sl<BookingRemoteDataSource>(), _shopId);
      if (mounted) setState(() => _rentedUntil = map);
    } catch (_) {
      // Best-effort (see the field doc): no return lines.
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  List<VehicleEntity> _filteredFleet(List<VehicleEntity> fleet) {
    const statuses = {'Available': 'available', 'On Rent': 'rented', 'Maintenance': 'maintenance'};
    var result = fleet;
    final status = statuses[_selectedFilter];
    if (status != null) result = result.where((v) => v.status == status).toList();
    // Audit §4: search by name or plate.
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) result = result.where((v) => v.displayName.toLowerCase().contains(q) || v.plateNumber.toLowerCase().contains(q)).toList();
    return result;
  }

  /// Audit §5 (item 15): the card opens the OWNER vehicle-detail
  /// route — the customer detail route it used to reuse is gone.
  void _openVehicleDetail(VehicleEntity v) =>
      _pushOnce(RouteNames.ownerVehicleDetail.replaceFirst(':id', v.vehicleId));

  /// Audit §5 (P2-5): adding a car is gated on shop approval — a
  /// 'pending' shop sees the gate dialog instead of the add flow.
  void _openAddVehicle() async {
    if (widget.onAddVehicle != null) {
      widget.onAddVehicle!();
      return;
    }
    final allowed = await FleetAddGate.ensureApproved(context, _shopId);
    if (!allowed || !mounted) return;
    // Audit impl (worker E, S6): the plan car cap is enforced when
    // opening Add Vehicle — at the cap the sheet offers the upgrade
    // instead of the add flow. The cap is the plan's real limit
    // (Free 3, Pro 10, Business unlimited).
    final currentFleet = _cubit.state is FleetLoaded
        ? (_cubit.state as FleetLoaded).vehicles
        : const <VehicleEntity>[];
    final subscription =
        await SubscriptionDataSource().getShopSubscription(_shopId);
    final plan = subscriptionPlanFor(subscription.tier);
    final carLimit = plan.carLimit;
    if (carLimit != null && currentFleet.length >= carLimit) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final planName = switch (plan.id) {
        'pro' => l10n.subscriptionPlanPro,
        'business' => l10n.subscriptionPlanBusiness,
        _ => l10n.subscriptionPlanFree,
      };
      await CarLimitSheet.show(
        context,
        carsUsed: currentFleet.length,
        carLimit: carLimit,
        planName: planName,
      );
      return;
    }
    _pushOnce(RouteNames.ownerAddVehicle).then((_) {
      if (mounted) { _cubit.loadVehicles(_shopId); _loadRentedUntil(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: SafeArea(
          // C1: MinimalAppBar owns the top inset; a second SafeArea would add a dead navy band above the header.
          top: false,
          child: BlocBuilder<FleetCubit, FleetState>(
            builder: (context, state) {
              final fleet = state is FleetLoaded ? state.vehicles : const <VehicleEntity>[];
              final filtered = _filteredFleet(fleet);
              final totalCount = fleet.length;
              final availableCount = fleet.where((v) => v.status == 'available').length;
              final onRentCount = fleet.where((v) => v.status == 'rented').length;
              final maintenanceCount = fleet.where((v) => v.status == 'maintenance').length;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // #9/#12/#15: MinimalAppBar with tinted chips; the header scrolls with the list as before.
                    MinimalAppBar(
                      title: l10n.fleetTitle,
                      subtitle: l10n.fleetSubtitle,
                      actions: [
                        AppIconChip(icon: Icons.route_rounded, tooltip: l10n.fixedRoutes, background: Colors.white.withValues(alpha: 0.15), iconColor: Colors.white, onPressed: () => context.push(RouteNames.ownerFixedRoutes)),
                        const SizedBox(width: 8),
                        // Audit §5 (O31): "Schedule" opens the multi-car calendar.
                        AppIconChip(icon: Icons.calendar_month_rounded, tooltip: l10n.fleetSchedule, background: Colors.white.withValues(alpha: 0.15), iconColor: Colors.white, onPressed: () => _pushOnce(RouteNames.ownerFleetCalendar)),
                        const SizedBox(width: 8),
                        AppIconChip(icon: Icons.add_circle_rounded, tooltip: l10n.fleetAddVehicle, background: Colors.white.withValues(alpha: 0.15), iconColor: Colors.white, onPressed: _openAddVehicle),
                      ],
                    ),

                    // Metrics Row (extracted: FleetMetricsRow).
                    FleetMetricsRow(
                      totalCount: totalCount,
                      availableCount: availableCount,
                      onRentCount: onRentCount,
                    ),

                    // Phone-test round 4: quick actions directly
                    // beneath the KPI tiles. Cross-branch destinations
                    // (Requests, Customers, QR scan) use `go` — the
                    // tab-switch semantic used elsewhere for those
                    // branches; same-branch ones use `_pushOnce`.
                    FleetQuickActions(
                      onHandover: () => context.go(RouteNames.ownerQrScan),
                      onRequests: () => context.go(RouteNames.ownerRequests),
                      onAddVehicle: _openAddVehicle,
                      onSchedule: () => _pushOnce(RouteNames.ownerFleetCalendar),
                      onCustomers: () => context.go(RouteNames.ownerCustomers),
                    ),

                    // Audit §5 (O05/O30): "N active rentals" header count.
                    if (onRentCount > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Text(l10n.fleetActiveRentals(onRentCount), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      ),

                    // Audit §4: search (name/plate) above the chips.
                    FleetSearchField(
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),

                    // Filter Chips
                    FleetFilterChips(
                      selectedFilter: _selectedFilter,
                      totalCount: totalCount,
                      availableCount: availableCount,
                      onRentCount: onRentCount,
                      maintenanceCount: maintenanceCount,
                      onSelected: (label) => setState(() => _selectedFilter = label),
                    ),
                    const Divider(height: 1),

                    // D3: medium+ shows two columns; compact keeps
                    // FleetBody (see FleetListSection).
                    FleetListSection(
                      state: state,
                      fleet: fleet,
                      filtered: filtered,
                      onAddVehicle: _openAddVehicle,
                      onRetry: () { _cubit.loadVehicles(_shopId); _loadRentedUntil(); },
                      onEditRates: (v) => _pushOnce(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)),
                      onOutCityRules: (v) => _pushOnce(RouteNames.ownerOutCityRules.replaceFirst(':vehicleId', v.vehicleId)),
                      onEditDetails: (v) => _pushOnce(RouteNames.ownerEditVehicle.replaceFirst(':id', v.vehicleId)),
                      onTapVehicle: _openVehicleDetail,
                      // RQ-F10: the active booking's return date.
                      rentedUntilFor: (v) => _rentedUntil[v.vehicleId],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
