import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_icon_chip.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/cubit/fleet_state.dart';
import '../widgets/fleet/fleet_body.dart';
import '../widgets/fleet/fleet_filter_chips.dart';
import '../widgets/fleet/fleet_metric_card.dart';
import '../widgets/fleet/fleet_vehicle_card.dart';

/// Phase B (B1): the fleet list now reads real vehicles through
/// [FleetCubit] (Firestore, with the in-memory fallback when offline)
/// instead of `MockDatabase.vehicles`. Status values are the entity's
/// lowercase ones ('available' | 'rented' | 'maintenance'); the toggle
/// writes back through the cubit, and the rates button opens the
/// per-vehicle rate matrix (Phase A route `/owner/rates/:vehicleId`).
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

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    _cubit = sl<FleetCubit>()..loadVehicles(_shopId);
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

  /// Audit §4: the card photo pushes the vehicle-detail route. The owner module has no own detail route (router out of scope), so this reuses the existing customer vehicle-detail route.
  void _openVehicleDetail(VehicleEntity v) => context.push(RouteNames.customerVehicleDetail.replaceFirst(':id', v.vehicleId));

  void _openAddVehicle() {
    if (widget.onAddVehicle != null) {
      widget.onAddVehicle!();
      return;
    }
    context.push(RouteNames.ownerAddVehicle).then((_) {
      if (mounted) _cubit.loadVehicles(_shopId);
    });
  }

  void _toggle(VehicleEntity v, bool val) => _cubit.updateVehicleStatus(shopId: _shopId, vehicleId: v.vehicleId, status: val ? 'available' : 'maintenance');

  /// D3: one fleet card for both the compact list and the two-column grid.
  Widget _vehicleCard(VehicleEntity v) => FleetVehicleCard(
        vehicle: v,
        onTap: () => _openVehicleDetail(v),
        onToggleAvailability: (val) => _toggle(v, val),
        onEditRates: () => context.push(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)),
        onViewCalendar: () => context.push(RouteNames.ownerCalendar.replaceFirst(':vehicleId', v.vehicleId)),
      );

  /// D3: medium+ shows the fleet in two columns.
  Widget _twoColumnFleet(List<VehicleEntity> vehicles) => twoColumnLayout(key: const Key('fleet-two-columns'), items: vehicles, padding: const EdgeInsets.all(16), itemBuilder: _vehicleCard);

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
                        AppIconChip(icon: Icons.add_circle_rounded, tooltip: l10n.fleetAddVehicle, background: Colors.white.withValues(alpha: 0.15), iconColor: Colors.white, onPressed: _openAddVehicle),
                      ],
                    ),

                    // Metrics Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Theme.of(context).colorScheme.surface,
                      child: Row(
                        children: [
                          FleetMetricCard(label: l10n.fleetTotalFleet, value: l10n.fleetTotalCars(totalCount), icon: Icons.directions_car_rounded, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          FleetMetricCard(label: l10n.available, value: l10n.fleetAvailableReady(availableCount), icon: Icons.check_circle_outline_rounded, color: AppColors.accentSuccess),
                          const SizedBox(width: 8),
                          // Audit §4: the On-Rent value is small text, so it uses the brightness-aware orange TEXT token in both modes (light #C2410C 5.18:1, dark #FB923C 7.92:1) — never the #F95700 fill as text.
                          FleetMetricCard(label: l10n.fleetOnRent, value: l10n.fleetOnRentActive(onRentCount), icon: Icons.key_rounded, color: AppColors.orangeTextFor(Theme.of(context).brightness)),
                        ],
                      ),
                    ),

                    // Audit §4: search (name/plate) above the chips.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        onChanged: (q) => setState(() => _searchQuery = q),
                        decoration: InputDecoration(
                          hintText: l10n.fleetSearchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
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

                    // D3: medium+ shows two columns; compact keeps FleetBody.
                    if (isMediumOrLarger(context) && filtered.isNotEmpty)
                      _twoColumnFleet(filtered)
                    else
                      FleetBody(
                        state: state,
                        fleet: fleet,
                        filtered: filtered,
                        onAddVehicle: _openAddVehicle,
                        onRetry: () => _cubit.loadVehicles(_shopId),
                        onToggleAvailability: _toggle,
                        onEditRates: (v) => context.push(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)),
                        onViewCalendar: (v) => context.push(RouteNames.ownerCalendar.replaceFirst(':vehicleId', v.vehicleId)),
                        onTapVehicle: _openVehicleDetail,
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
