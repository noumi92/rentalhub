import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'widgets/customer_vehicle_card.dart';

/// B3: the shop's fleet screen, converted from MockVehicle to the real
/// [VehicleEntity]. Without a [vehicles] list it loads the shop's real
/// fleet from Firestore — the old version fell back to the mock database.
class ShopCarsView extends StatefulWidget {
  final String shopId;
  final String shopName;
  final List<VehicleEntity>? vehicles;
  final ValueChanged<VehicleEntity>? onCarSelected;
  final VoidCallback? onBack;

  const ShopCarsView({
    super.key,
    required this.shopId,
    required this.shopName,
    this.vehicles,
    this.onCarSelected,
    this.onBack,
  });

  @override
  State<ShopCarsView> createState() => _ShopCarsViewState();
}

class _ShopCarsViewState extends State<ShopCarsView> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Sedan', 'SUV', 'Hiace', 'Luxury'];
  List<VehicleEntity> _loaded = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicles == null) {
      _loading = true;
      sl<FleetRemoteDataSource>()
          .getShopVehicles(widget.shopId)
          .then((vehicles) {
        if (mounted) {
          setState(() {
            _loaded = vehicles;
            _loading = false;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.vehicles ?? _loaded;
    final filtered = _selectedCategory == 'All'
        ? list
        : list.where((v) => v.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Fleet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(widget.shopName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.white : AppColors.primary),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_outlined,
                              size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'No $_selectedCategory vehicles available right now.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final car = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomerVehicleCard(
                            vehicle: car,
                            onTap: () => widget.onCarSelected?.call(car),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
