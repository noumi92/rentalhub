import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/cubit/fleet_state.dart';
import '../widgets/fleet/fleet_body.dart';
import '../widgets/fleet/fleet_metric_card.dart';

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
    switch (_selectedFilter) {
      case 'Available':
        return fleet.where((v) => v.status == 'available').toList();
      case 'On Rent':
        return fleet.where((v) => v.status == 'rented').toList();
      case 'Maintenance':
        return fleet.where((v) => v.status == 'maintenance').toList();
      case 'All':
      default:
        return fleet;
    }
  }

  void _openAddVehicle() {
    if (widget.onAddVehicle != null) {
      widget.onAddVehicle!();
      return;
    }
    context.push(RouteNames.ownerAddVehicle).then((_) {
      if (mounted) _cubit.loadVehicles(_shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: BlocBuilder<FleetCubit, FleetState>(
            builder: (context, state) {
              final fleet =
                  state is FleetLoaded ? state.vehicles : const <VehicleEntity>[];
              final filtered = _filteredFleet(fleet);
              final totalCount = fleet.length;
              final availableCount =
                  fleet.where((v) => v.status == 'available').length;
              final onRentCount =
                  fleet.where((v) => v.status == 'rented').length;
              final maintenanceCount =
                  fleet.where((v) => v.status == 'maintenance').length;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header rolls up with scroll (Requirement 1)
                    CustomCurvedHeader(
                      height: 115,
                      leadingWidget: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(RouteNames.onboardingRole);
                          }
                        },
                      ),
                      titleWidget: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fleet Management',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                          SizedBox(height: 2),
                          Text('Live Showroom',
                              style: TextStyle(
                                  color: AppColors.textLavender, fontSize: 12)),
                        ],
                      ),
                      actions: [
                        IconButton(
                          tooltip: 'Fixed Routes',
                          icon: const Icon(Icons.route_rounded,
                              color: Colors.white, size: 24),
                          onPressed: () =>
                              context.push(RouteNames.ownerFixedRoutes),
                        ),
                        IconButton(
                          tooltip: 'Add Vehicle',
                          icon: const Icon(Icons.add_circle_rounded,
                              color: AppColors.sunsetOrange, size: 28),
                          onPressed: _openAddVehicle,
                        ),
                      ],
                    ),

                    // Metrics Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          FleetMetricCard(
                              label: 'Total Fleet',
                              value: '$totalCount Cars',
                              icon: Icons.directions_car_rounded,
                              color: AppColors.midnightNavy),
                          const SizedBox(width: 8),
                          FleetMetricCard(
                              label: 'Available',
                              value: '$availableCount Ready',
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.emeraldGreen),
                          const SizedBox(width: 8),
                          FleetMetricCard(
                              label: 'On Rent',
                              value: '$onRentCount Active',
                              icon: Icons.key_rounded,
                              color: AppColors.sunsetOrange),
                        ],
                      ),
                    ),

                    // Filter Chips
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      color: Colors.white,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('All', totalCount),
                          const SizedBox(width: 8),
                          _filterChip('Available', availableCount),
                          const SizedBox(width: 8),
                          _filterChip('On Rent', onRentCount),
                          const SizedBox(width: 8),
                          _filterChip('Maintenance', maintenanceCount),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    FleetBody(
                      state: state,
                      fleet: fleet,
                      filtered: filtered,
                      onAddVehicle: _openAddVehicle,
                      onRetry: () => _cubit.loadVehicles(_shopId),
                      onToggleAvailability: (v, val) {
                        _cubit.updateVehicleStatus(
                          shopId: _shopId,
                          vehicleId: v.vehicleId,
                          status: val ? 'available' : 'maintenance',
                        );
                      },
                      onEditRates: (v) => context.push(
                        RouteNames.ownerRatesVehicle.replaceFirst(
                            ':vehicleId', v.vehicleId),
                      ),
                      onViewCalendar: (v) => context.push(
                        RouteNames.ownerCalendar.replaceFirst(
                            ':vehicleId', v.vehicleId),
                      ),
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

  Widget _filterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: AppColors.sunsetOrange,
      backgroundColor: AppColors.backgroundLight,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : AppColors.midnightNavy,
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }
}
