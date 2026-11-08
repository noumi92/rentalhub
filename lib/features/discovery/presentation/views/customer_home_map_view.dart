import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../data/datasources/customer_location_store.dart';
import '../../data/datasources/discovery_remote_data_source.dart';
import '../../data/repositories/discovery_repository_impl.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_nearby_shops_usecase.dart';
import 'widgets/customer_map_canvas.dart';
import 'widgets/map_shop_preview_card.dart';
import 'widgets/no_shops_banner.dart';
import 'widgets/radius_filter_pills.dart';

/// B2: the map view runs on real data. The centre is the customer's
/// stored location (refreshed with a live GPS fix when one is available),
/// the markers are the verified shops from Firestore within the selected
/// radius, and changing the radius re-fetches — the old version showed 4
/// hardcoded shops around a hardcoded Gulberg III pin.
class CustomerHomeMapView extends StatefulWidget {
  const CustomerHomeMapView({super.key});

  @override
  State<CustomerHomeMapView> createState() => _CustomerHomeMapViewState();
}

class _CustomerHomeMapViewState extends State<CustomerHomeMapView> {
  final MapController _mapController = MapController();
  final _locationStore = CustomerLocationStore();
  late final GetNearbyShopsUseCase _getNearbyShops;

  double _selectedRadiusKm = 3.0;
  CustomerLocation _location = CustomerLocation.defaultLocation;
  List<ShopEntity> _shops = const [];
  ShopEntity? _selectedShop;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getNearbyShops = GetNearbyShopsUseCase(
      DiscoveryRepositoryImpl(
        remoteDataSource: DiscoveryRemoteDataSource(),
      ),
    );
    _loadFromStoredLocation();
  }

  Future<void> _loadFromStoredLocation() async {
    final stored = await _locationStore.load();
    if (stored != null && mounted) {
      setState(() => _location = stored);
      _mapController.move(_latLng(stored), 13.5);
    }
    await _loadShops();
    await _refreshGpsFix();
  }

  /// A fresh GPS fix, when the device offers one: the stored location may
  /// be from an earlier session. Never asks for permission here — the
  /// location prompt already did; without it we silently keep the stored
  /// location.
  Future<void> _refreshGpsFix() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final fix = CustomerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: 'My Live Location',
        area:
            '${position.latitude.toStringAsFixed(4)}°N, ${position.longitude.toStringAsFixed(4)}°E',
        fromGps: true,
      );
      if ((fix.latitude - _location.latitude).abs() > 0.0005 ||
          (fix.longitude - _location.longitude).abs() > 0.0005) {
        setState(() => _location = fix);
        _mapController.move(_latLng(fix), 14.5);
        await _loadShops();
      }
    } catch (_) {
      // No fix available — the stored location stands.
    }
  }

  Future<void> _loadShops() async {
    setState(() => _loading = true);
    try {
      final shops = await _getNearbyShops(
        radiusKm: _selectedRadiusKm,
        latitude: _location.latitude,
        longitude: _location.longitude,
      );
      if (!mounted) return;
      setState(() {
        _shops = shops;
        _selectedShop = shops.isEmpty ? null : shops.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shops = const [];
        _selectedShop = null;
        _loading = false;
      });
    }
  }

  ll.LatLng _latLng(CustomerLocation location) =>
      ll.LatLng(location.latitude, location.longitude);

  @override
  Widget build(BuildContext context) {
    final userPoint = _latLng(_location);
    final selectedShop = _selectedShop;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 110,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nearby Showrooms', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('${_location.area} • Tap marker to preview', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Switch to List View',
                  onPressed: () => context.go(RouteNames.customerHome),
                  icon: const Icon(Icons.view_list_rounded, color: AppColors.secondary, size: 24),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: RadiusFilterPills(
                selectedRadiusKm: _selectedRadiusKm,
                onRadiusSelected: (km) {
                  setState(() => _selectedRadiusKm = km);
                  _loadShops();
                },
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  CustomerMapCanvas(
                    mapController: _mapController,
                    userPoint: userPoint,
                    radiusKm: _selectedRadiusKm,
                    shops: _shops,
                    selectedShop: selectedShop,
                    onShopSelected: (shop) =>
                        setState(() => _selectedShop = shop),
                  ),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (!_loading && _shops.isEmpty)
                    const Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: NoShopsBanner(),
                    )
                  else if (selectedShop != null)
                    MapShopPreviewCard(
                      shop: selectedShop,
                      onViewShowroom: () {
                        context.push(
                          RouteNames.customerShopDetail.replaceFirst(
                            ':shopId',
                            selectedShop.shopId,
                          ),
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

