import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../widgets/fleet/fleet_metric_card.dart';
import '../widgets/fleet/fleet_vehicle_card.dart';
import 'owner_add_vehicle_view.dart';

class OwnerFleetView extends StatefulWidget {
  const OwnerFleetView({super.key});

  @override
  State<OwnerFleetView> createState() => _OwnerFleetViewState();
}

class _OwnerFleetViewState extends State<OwnerFleetView> {
  String _selectedFilter = 'All';
  late List<MockVehicle> _fleet;

  @override
  void initState() {
    super.initState();
    _fleet = List.from(MockDatabase.vehicles);
  }

  List<MockVehicle> get _filteredFleet {
    if (_selectedFilter == 'Available') {
      return _fleet.where((v) => v.status == 'Available').toList();
    } else if (_selectedFilter == 'On Rent') {
      return _fleet.where((v) => v.status == 'Rented').toList();
    } else if (_selectedFilter == 'Maintenance') {
      return _fleet.where((v) => v.status == 'Maintenance').toList();
    }
    return _fleet;
  }

  void _openAddVehicle() async {
    final addedVehicle = await Navigator.of(context).push<MockVehicle>(
      MaterialPageRoute(
        builder: (_) => OwnerAddVehicleView(
          onVehicleAdded: (v) {
            setState(() {
              _fleet.insert(0, v);
            });
          },
        ),
      ),
    );

    if (addedVehicle != null && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFleet;
    final totalCount = _fleet.length;
    final availableCount = _fleet.where((v) => v.status == 'Available').length;
    final onRentCount = _fleet.where((v) => v.status == 'Rented').length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header rolls up with scroll (Requirement 1)
              CustomCurvedHeader(
                height: 115,
                leadingWidget: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
                    Text('Fleet Management', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text('Al-Falah Rent a Car • Live Showroom', style: TextStyle(color: AppColors.textLavender, fontSize: 12)),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Add Vehicle',
                    icon: const Icon(Icons.add_circle_rounded, color: AppColors.sunsetOrange, size: 28),
                    onPressed: _openAddVehicle,
                  ),
                ],
              ),

              // Metrics Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    FleetMetricCard(label: 'Total Fleet', value: '$totalCount Cars', icon: Icons.directions_car_rounded, color: AppColors.midnightNavy),
                    const SizedBox(width: 8),
                    FleetMetricCard(label: 'Available', value: '$availableCount Ready', icon: Icons.check_circle_outline_rounded, color: AppColors.emeraldGreen),
                    const SizedBox(width: 8),
                    FleetMetricCard(label: 'On Rent', value: '$onRentCount Active', icon: Icons.key_rounded, color: AppColors.sunsetOrange),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    _filterChip('Maintenance', 0),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Fleet List
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.no_crash_rounded, size: 54, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('No vehicles found in this filter', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _openAddVehicle,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Vehicle Now'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunsetOrange, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final v = filtered[index];
                    return FleetVehicleCard(
                      vehicle: v,
                      onToggleAvailability: (val) {
                        setState(() {
                          final idx = _fleet.indexWhere((car) => car.id == v.id);
                          if (idx != -1) {
                            _fleet[idx] = v.copyWith(status: val ? 'Available' : 'Maintenance');
                          }
                        });
                      },
                      onEditRates: () {},
                    );
                  },
                ),
            ],
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
