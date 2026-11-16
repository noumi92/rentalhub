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
import '../services/subscription_data_source.dart';
import 'owner_subscription_limit_sheet.dart';

/// Fleet screen (user layout, 2026-11-16): the controls are split
/// between the AppBar and a floating button — Schedule, Handover QR
/// and Requests are icon buttons in the AppBar (in that order),
/// "+ Add Vehicle" is an extended floating action button, and the
/// filter bar ([FleetFilterChips]: All / Ready / On Rent /
/// Maintenance) sits directly on the scaffold with no search bar
/// and no quick-actions row above it. Nothing is dropped: every
/// destination from the old layout is still reachable (Customers
/// stays on the Customers tab in the bottom nav).
class OwnerFleetView extends StatefulWidget {
  final String? shopId;
  final VoidCallback? onAddVehicle;
  const OwnerFleetView({super.key, this.shopId, this.onAddVehicle});

  @override
  State<OwnerFleetView> createState() => _OwnerFleetViewState();
}

class _OwnerFleetViewState extends State<OwnerFleetView> {
  String _selectedFilter = 'All';
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
        // User layout 2026-11-16: "+ Add Vehicle" is an extended
        // floating button (orangeFill #C2410C, white icon + label
        // 5.18:1) instead of the old AppBar pill. It calls the same
        // gated [_openAddVehicle] — shop approval + plan car cap —
        // and keeps the `fleet-action-add-vehicle` key so tests keep
        // addressing it. Standard Scaffold placement puts it above
        // the bottom tab bar. Unique heroTag: the shell keeps all
        // branches mounted, so the default tag could collide with
        // another tab's FAB.
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('fleet-action-add-vehicle'),
          heroTag: 'fleet-add-vehicle',
          onPressed: _openAddVehicle,
          tooltip: l10n.fleetAddVehicle,
          backgroundColor: AppColors.orangeFill,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(l10n.fleetAddVehicle),
        ),
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
                    // User layout 2026-11-16: the AppBar carries only
                    // icon actions — Schedule, Handover QR, Requests,
                    // in that order (white icons on the navy bar; E3
                    // tooltips carry the labels). "+ Add Vehicle"
                    // moved to the extended FAB below; Customers left
                    // the fleet screen (still on the Customers tab).
                    MinimalAppBar(
                      title: l10n.fleetTitle,
                      subtitle: l10n.fleetSubtitle,
                      actions: [
                        IconButton(key: const Key('fleet-action-schedule'), tooltip: l10n.fleetSchedule, icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22), onPressed: () => _pushOnce(RouteNames.ownerFleetCalendar)),
                        IconButton(key: const Key('fleet-action-handover'), tooltip: l10n.fleetHandoverQr, icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22), onPressed: () => context.go(RouteNames.ownerQrScan)),
                        IconButton(key: const Key('fleet-action-requests'), tooltip: l10n.navRequests, icon: const Icon(Icons.inbox_rounded, color: Colors.white, size: 22), onPressed: () => context.go(RouteNames.ownerRequests)),
                      ],
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
