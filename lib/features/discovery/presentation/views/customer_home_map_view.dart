import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../domain/entities/shop_entity.dart';
import 'shop_detail_view.dart';
import 'widgets/map_shop_preview_card.dart';
import 'widgets/radius_filter_pills.dart';

class CustomerHomeMapView extends StatefulWidget {
  const CustomerHomeMapView({super.key});

  @override
  State<CustomerHomeMapView> createState() => _CustomerHomeMapViewState();
}

class _CustomerHomeMapViewState extends State<CustomerHomeMapView> {
  final MapController _mapController = MapController();
  double _selectedRadiusKm = 3.0;
  final ll.LatLng _userLocation = const ll.LatLng(31.5204, 74.3587); // Gulberg III

  final List<ShopEntity> _allShops = [
    const ShopEntity(
      shopId: 'shop-01',
      ownerId: 'owner-01',
      shopName: 'Al-Buraq Motors & Car Rentals',
      phoneNumber: '+92 300 1234567',
      address: 'Main Boulevard, Gulberg III',
      city: 'Lahore',
      geoLocation: GeoPointEntity(31.5230, 74.3595),
      distanceKm: 1.2,
      rating: 4.9,
      availableCount: 14,
      isVerified: true,
    ),
    const ShopEntity(
      shopId: 'shop-02',
      ownerId: 'owner-02',
      shopName: 'Royal Rent A Car Gulberg',
      phoneNumber: '+92 321 9876543',
      address: 'Near Liberty Roundabout, Gulberg III',
      city: 'Lahore',
      geoLocation: GeoPointEntity(31.5160, 74.3640),
      distanceKm: 2.1,
      rating: 4.8,
      availableCount: 9,
      isVerified: true,
    ),
    const ShopEntity(
      shopId: 'shop-03',
      ownerId: 'owner-03',
      shopName: 'Falcon Fleet & Executive Transport',
      phoneNumber: '+92 333 4567890',
      address: 'Jail Road, Shadman',
      city: 'Lahore',
      geoLocation: GeoPointEntity(31.5350, 74.3480),
      distanceKm: 2.8,
      rating: 4.7,
      availableCount: 18,
      isVerified: true,
    ),
    const ShopEntity(
      shopId: 'shop-04',
      ownerId: 'owner-04',
      shopName: 'Lahore Wheels & 4x4 Luxury',
      phoneNumber: '+92 302 8899112',
      address: 'DHA Phase 5 Commercial',
      city: 'Lahore',
      geoLocation: GeoPointEntity(31.4720, 74.3850),
      distanceKm: 4.5,
      rating: 4.95,
      availableCount: 6,
      isVerified: true,
    ),
  ];

  late ShopEntity _selectedShop;

  @override
  void initState() {
    super.initState();
    _selectedShop = _allShops.first;
  }

  List<ShopEntity> get _filteredShops => _allShops.where((s) => s.distanceKm <= _selectedRadiusKm).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredShops;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 110,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => context.go(RouteNames.customerHome),
              ),
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nearby Showrooms', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text('Gulberg III, Lahore • Tap marker to preview', style: TextStyle(color: AppColors.textLavender, fontSize: 12)),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Switch to List View',
                  onPressed: () => context.go(RouteNames.customerHome),
                  icon: const Icon(Icons.view_list_rounded, color: AppColors.sunsetOrange, size: 24),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: RadiusFilterPills(
                selectedRadiusKm: _selectedRadiusKm,
                onRadiusSelected: (km) => setState(() => _selectedRadiusKm = km),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _userLocation,
                      initialZoom: 13.5,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'pk.rentalhub.rentalhub',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _userLocation,
                            radius: 1200,
                            useRadiusInMeter: true,
                            color: AppColors.sunsetOrange.withValues(alpha: 0.10),
                            borderColor: AppColors.sunsetOrange,
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userLocation,
                            width: 38,
                            height: 38,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6)],
                              ),
                              child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          ...filtered.map((shop) {
                            final isSelected = _selectedShop.shopId == shop.shopId;
                            final pos = ll.LatLng(shop.geoLocation.latitude, shop.geoLocation.longitude);
                            return Marker(
                              point: pos,
                              width: 150,
                              height: 72,
                              alignment: Alignment.bottomCenter,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedShop = shop);
                                  _mapController.move(pos, 14.0);
                                },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.bottomCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.sunsetOrange : AppColors.midnightNavy,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
                                        ),
                                        child: Text(
                                          '${shop.shopName.split(' ').first} • ${shop.distanceKm}km',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Icon(Icons.location_on_rounded, size: isSelected ? 32 : 26, color: isSelected ? AppColors.sunsetOrange : AppColors.midnightNavy),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  MapShopPreviewCard(
                    shop: _selectedShop,
                    onViewShowroom: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ShopDetailView(shop: _selectedShop)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
