import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/verified_badge.dart';
import 'widgets/shop_vehicle_card.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../domain/entities/shop_entity.dart';

/// Phase A (A1): the shop detail screen now loads the shop's real fleet
/// from Firestore instead of the mock database. A shop with no cars shows
/// an honest empty state instead of every mock car in the app.
class ShopDetailView extends StatefulWidget {
  final ShopEntity shop;
  final ValueChanged<VehicleEntity>? onVehicleSelected;
  final VoidCallback? onViewAllCars;
  final VoidCallback? onBack;

  const ShopDetailView({
    super.key,
    required this.shop,
    this.onVehicleSelected,
    this.onViewAllCars,
    this.onBack,
  });

  @override
  State<ShopDetailView> createState() => _ShopDetailViewState();
}

class _ShopDetailViewState extends State<ShopDetailView> {
  List<VehicleEntity>? _vehicles;
  bool _loading = true;

  // H5: whether this showroom is saved by the signed-in customer.
  CustomerEntity? _customer;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final customer =
          await sl<CustomerRemoteDataSource>().getCustomerById(uid);
      if (mounted && customer != null) {
        setState(() {
          _customer = customer;
          _saved = customer.savedShopIds.contains(widget.shop.shopId);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleSaved() async {
    final customer = _customer;
    if (customer == null) {
      AppFeedback.showInfo(context, 'Sign in to save showrooms.');
      return;
    }
    final ids = List<String>.from(customer.savedShopIds);
    final nowSaved = !ids.contains(widget.shop.shopId);
    if (nowSaved) {
      ids.add(widget.shop.shopId);
    } else {
      ids.remove(widget.shop.shopId);
    }
    final updated = customer.copyWith(savedShopIds: ids);
    setState(() {
      _customer = updated;
      _saved = nowSaved;
    });
    try {
      await sl<CustomerRemoteDataSource>().upsertCustomer(updated);
    } catch (_) {
      if (mounted) {
        setState(() {
          _customer = customer;
          _saved = !nowSaved;
        });
        AppFeedback.showError(context, 'Could not save this showroom.');
      }
    }
  }

  Future<void> _loadVehicles() async {
    final list = await sl<FleetRemoteDataSource>()
        .getShopVehicles(widget.shop.shopId);
    if (mounted) {
      setState(() {
        _vehicles = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final vehicles = _vehicles ?? const <VehicleEntity>[];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCurvedHeader(
              height: 170,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.shopName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${shop.address}, ${shop.city} (${shop.distanceKm} km)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer),
                  ),
                ],
              ),
              bottomWidget: VerifiedBadge(isVerified: shop.isVerified),
              actions: [
                IconButton(
                  icon: Icon(
                    _saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: _saved ? 'Saved' : 'Save showroom',
                  onPressed: _toggleSaved,
                ),
              ],
            ),
            HeaderOverlapContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (vehicles.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'This shop has no cars listed yet.',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else ...[
                      ...vehicles.map(
                        (vehicle) => ShopVehicleCard(
                          vehicle: vehicle,
                          onTap: () =>
                              widget.onVehicleSelected?.call(vehicle),
                        ),
                      ),
                      if (widget.onViewAllCars != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: widget.onViewAllCars,
                              icon: const Icon(
                                Icons.directions_car_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'View all cars with filters',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
