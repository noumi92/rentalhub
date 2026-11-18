import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/cubit/fleet_state.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/live_booking_stream.dart';
import '../widgets/fleet/fleet_helpers.dart';
import '../widgets/fleet/fleet_list_section.dart';
import '../widgets/fleet/fleet_rented_until.dart';
import '../widgets/fleet/fleet_filter_chips.dart';
import '../widgets/fleet/fleet_search_field.dart';
import '../widgets/fleet/fleet_add_vehicle_pill.dart';
import '../services/subscription_data_source.dart';
import 'owner_subscription_limit_sheet.dart';

/// Fleet screen (user layout, 2026-11-18): two top rows, both in
/// the navy header. Row 1 is the title row — title + shop subtitle
/// and a compact orange "+ Add Vehicle" pill (the extended FAB
/// overlapped the third card on a phone). No header icons: the
/// reference design shows title + pill only. Row 2 is the white
/// search bar inside the header — a name/plate search that actually
/// filters the list, a divider, then Schedule (icon-only — the fleet
/// calendar is reachable only from here), Handover QR and Requests
/// as inline buttons. (MinimalAppBar has no `bottom` slot, so the
/// header + search bar share one navy container — visually the same
/// as an AppBar.bottom.) The filter bar ([FleetFilterChips]: All /
/// Ready / On Rent / Maintenance when any car is in maintenance)
/// sits below that, directly on the scaffold. Nothing is dropped:
/// every destination from the old layout is still reachable
/// (Customers stays on the Customers tab in the bottom nav).
class OwnerFleetView extends StatefulWidget {
  final String? shopId;
  final VoidCallback? onAddVehicle;
  const OwnerFleetView({super.key, this.shopId, this.onAddVehicle});

  @override
  State<OwnerFleetView> createState() => _OwnerFleetViewState();
}

class _OwnerFleetViewState extends State<OwnerFleetView> {
  String _selectedFilter = 'All';

  /// Search query from the header search bar (name or plate).
  String _searchQuery = '';
  late final FleetCubit _cubit;

  /// RQ-F10: the active booking's return date per vehicle (same
  /// shop bookings the fleet calendar reads). Best-effort: a failed
  /// load leaves the map empty and the cards show no return line.
  Map<String, DateTime> _rentedUntil = {};
  // Live updates (Item 2): the subscription that keeps the return dates live — a new booking or a status change repaints the fleet cards without leaving the tab.
  StreamSubscription<List<BookingEntity>>? _bookingsSub;

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
    // Live updates (Item 2): the fleet cards' "On Rent until" lines follow the shop's bookings stream — a new booking or a status change repaints them without leaving the tab. The stream's first emission is the first paint; there is no one-time load any more.
    _bookingsSub = subscribeLiveBookings((ds) => ds.streamShopBookings(_shopId), (list) {
      if (mounted) setState(() => _rentedUntil = rentedUntilByVehicle(list));
    });
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _cubit.close();
    super.dispose();
  }

  List<VehicleEntity> _filteredFleet(List<VehicleEntity> fleet) {
    const statuses = {'Available': 'available', 'On Rent': 'rented', 'Maintenance': 'maintenance'};
    var result = fleet;
    final status = statuses[_selectedFilter];
    if (status != null) result = result.where((v) => v.status == status).toList();
    // Header search (user layout, 2026-11-18): name or plate,
    // case-insensitive, on top of the status filter.
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((v) => v.displayName.toLowerCase().contains(query) || v.plateNumber.toLowerCase().contains(query)).toList();
    }
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
      await CarLimitSheet.show(context, carsUsed: currentFleet.length, carLimit: carLimit, planName: planName);
      return;
    }
    _pushOnce(RouteNames.ownerAddVehicle).then((_) {
      if (mounted) _cubit.loadVehicles(_shopId);
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

              return RefreshIndicator(
                // Pull-to-refresh (user layout, 2026-11-16): reloads
                // the fleet via the cubit. Nothing else changes here.
                onRefresh: () => _cubit.loadVehicles(_shopId),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User layout 2026-11-18: the navy header holds
                    // BOTH top rows — the title row (orange "+ Add
                    // Vehicle" pill only; the FAB overlapped the
                    // third card) and the white search bar under it.
                    // Schedule, Handover QR and Requests live inside
                    // the search bar (same destinations the old
                    // header icons used); Customers left the fleet
                    // screen (still on the Customers tab).
                    Container(
                      color: AppColors.primaryDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MinimalAppBar(
                            title: l10n.fleetTitle,
                            subtitle: l10n.fleetSubtitle,
                            actions: [
                              FleetAddVehiclePill(onPressed: _openAddVehicle),
                            ],
                          ),
                          FleetSearchField(
                            onChanged: (query) => setState(() => _searchQuery = query),
                            onSchedule: () => _pushOnce(RouteNames.ownerFleetCalendar),
                            onHandover: () => context.go(RouteNames.ownerQrScan),
                            onRequests: () => context.go(RouteNames.ownerRequests),
                          ),
                        ],
                      ),
                    ),

                    // Phase 2: KPI boxes + filter chips merged into one
                    // segmented bar (All / Ready / On Rent /
                    // Maintenance — Total Fleet is the "All" count).
                    FleetFilterChips(
                      selectedFilter: _selectedFilter,
                      totalCount: totalCount,
                      availableCount: availableCount,
                      onRentCount: onRentCount,
                      maintenanceCount: maintenanceCount,
                      onSelected: (label) => setState(() => _selectedFilter = label),
                    ),

                    // Audit §5 (O05/O30): "N active rentals" header count.
                    if (onRentCount > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Text(l10n.fleetActiveRentals(onRentCount), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      ),

                    // D3: medium+ shows two columns; compact keeps
                    // FleetBody (see FleetListSection).
                    FleetListSection(
                      state: state,
                      fleet: fleet,
                      filtered: filtered,
                      onAddVehicle: _openAddVehicle,
                      onRetry: () => _cubit.loadVehicles(_shopId),
                      onEditRates: (v) => _pushOnce(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)),
                      onOutCityRules: (v) => _pushOnce(RouteNames.ownerOutCityRules.replaceFirst(':vehicleId', v.vehicleId)),
                      onEditDetails: (v) => _pushOnce(RouteNames.ownerEditVehicle.replaceFirst(':id', v.vehicleId)),
                      onTapVehicle: _openVehicleDetail,
                      // RQ-F10: the active booking's return date.
                      rentedUntilFor: (v) => _rentedUntil[v.vehicleId],
                    ),
                  ],
                ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
