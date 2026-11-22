import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/customer_location_store.dart';
import '../../domain/entities/shop_entity.dart';
import '../cubit/shops_filter_state.dart';
import 'widgets/map_gps_helper.dart';
import 'widgets/shops_filter_bar.dart';
import 'widgets/shops_filter_logic.dart';
import 'widgets/shops_location_note.dart';
import 'widgets/shops_map_canvas.dart';
import 'widgets/shops_tab_data.dart';

/// Full-screen Nearby showrooms map, reused as the Shops tab's map view.
class CustomerHomeMapView extends StatefulWidget {
  const CustomerHomeMapView({
    super.key,
    this.shopsLoader,
    this.displayUnverifiedLoader,
    this.isOnlineOverride,
    this.filterState,
    this.onShopSelected,
  });

  final Future<List<ShopEntity>> Function()? shopsLoader;
  final Future<bool> Function()? displayUnverifiedLoader;
  final bool? isOnlineOverride;
  final ShopsFilterState? filterState;
  final ValueChanged<ShopEntity>? onShopSelected;

  @override
  State<CustomerHomeMapView> createState() => _CustomerHomeMapViewState();
}

class _CustomerHomeMapViewState extends State<CustomerHomeMapView> {
  final MapController _mapController = MapController();
  late final ShopsFilterState _filters;
  List<ShopEntity> _shops = const [];
  ShopEntity? _selectedShop;
  bool _loading = true;
  bool _loadFailed = false;
  bool _online = true;
  bool _locating = false;
  bool? _locationAvailable;
  String? _lastCity;
  double _radiusKm = 3.0;
  bool _radiusFilterActive = false;

  @override
  void initState() {
    super.initState();
    _filters = widget.filterState ?? ShopsFilterState.shared;
    _lastCity = _filters.city;
    _filters.addListener(_onFiltersChanged);
    _loadShops();
    _checkLocation();
    _checkOnline();
    _loadStoredLocation();
    ShopsTabData.preselectCity(_filters);
  }

  @override
  void dispose() {
    _filters.removeListener(_onFiltersChanged);
    _mapController.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    if (_filters.city != _lastCity) {
      _lastCity = _filters.city;
      _mapController.move(_filters.mapCenter, _filters.mapZoom);
    }
    final filtered = _visibleShops();
    if (_selectedShop != null &&
        !filtered.any((s) => s.shopId == _selectedShop!.shopId)) {
      setState(() => _selectedShop = null);
    }
  }

  Future<void> _loadShops() async {
    final result = await ShopsTabData.loadShops(
      filters: _filters,
      shopsLoader: widget.shopsLoader,
      displayUnverifiedLoader: widget.displayUnverifiedLoader,
    );
    if (!mounted) return;
    setState(() {
      _shops = result.shops;
      _loadFailed = result.loadFailed;
      _loading = false;
    });
  }

  Future<void> _loadStoredLocation() async {
    if (_filters.userPoint != null) return;
    try {
      final stored = await CustomerLocationStore().load();
      if (!mounted || stored == null) return;
      _filters.setUserPoint(ll.LatLng(stored.latitude, stored.longitude));
    } catch (_) {}
  }

  ll.LatLng get _userPoint => _filters.userPoint ?? _filters.mapCenter;

  List<ShopEntity> _visibleShops() {
    final sorted = sortShopsByDistance(_filters.apply(_shops), _userPoint);
    return _radiusFilterActive
        ? filterShopsWithinRadius(sorted, _radiusKm)
        : sorted;
  }

  Future<void> _checkLocation() async {
    final ok = await ShopsTabData.locationAvailable();
    if (mounted) setState(() => _locationAvailable = ok);
  }

  Future<void> _checkOnline() async {
    final ok = await ShopsTabData.onlineStatus(override: widget.isOnlineOverride);
    if (mounted) setState(() => _online = ok);
  }

  Future<void> _recenterOnGps() async {
    setState(() => _locating = true);
    final res = await fetchCustomerGpsPoint(context, silent: false);
    if (!mounted) return;
    setState(() => _locating = false);
    if (res == null) return;
    _filters.setUserPoint(res.point);
    if (res.nearestCity != null) _filters.setCity(res.nearestCity);
    _mapController.move(res.point, 13.5);
    await persistCustomerPoint(res.point, city: res.nearestCity, fromGps: true);
  }

  void _selectRadius(double km) {
    setState(() {
      _radiusKm = km;
      _radiusFilterActive = true;
    });
    final zoom = km <= 2 ? 14.0 : (km <= 5 ? 12.5 : (km <= 10 ? 11.5 : 10.5));
    try {
      _mapController.move(_userPoint, zoom);
    } catch (_) {}
  }

  void _selectCity(Map<String, dynamic> city) =>
      _filters.setCity(city['all'] == true ? null : city['name'] as String);

  void _openShop(ShopEntity shop) {
    if (widget.onShopSelected != null) {
      widget.onShopSelected!.call(shop);
    } else {
      context.push(RouteNames.customerShopDetail.replaceFirst(':shopId', shop.shopId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _filters,
      builder: (context, _) {
        final shops = _visibleShops();
        final selectedShop = _selectedShop;
        return Scaffold(
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                MinimalAppBar(
                  title: l10n.homeNearbyShowrooms,
                  subtitle:
                      l10n.mapTapMarker(_filters.city ?? l10n.shops_allCities),
                  onBack: () => context.pop(),
                ),
                ShopsFilterBar(
                  majorCities: shopsCityMenuEntries(l10n),
                  selectedCity: _filters.city ?? l10n.shops_allCities,
                  onSelectCity: _selectCity,
                  verification: _filters.verification,
                  onVerificationChanged: _filters.setVerification,
                  showUnverifiedFilter: _filters.displayUnverifiedShops,
                ),
                if (_locationAvailable == false)
                  ShopsLocationNote(text: l10n.shops_chooseCity),
                Expanded(
                  child: _loadFailed
                      ? AppErrorState(
                          message: l10n.shops_loadFailed,
                          onRetry: _loadShops,
                        )
                      : Stack(
                          children: [
                            ShopsMapCanvas(
                              mapController: _mapController,
                              shops: shops,
                              isOnline: _online,
                              onShopSelected: (s) => setState(() => _selectedShop = s),
                              onMapTap: () {
                                if (_selectedShop != null) setState(() => _selectedShop = null);
                              },
                              initialCenter: _filters.mapCenter,
                              initialZoom: _filters.mapZoom,
                              userPoint: _userPoint,
                              onUserPointChanged: _filters.setUserPoint,
                              onUserPointChangeEnd: (pt) => persistCustomerPoint(pt, city: _filters.city),
                              radiusKm: _radiusKm,
                            ),
                            if (_loading) const AppLoadingState(),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: MapGpsFab(
                                heroTag: 'nearby_map_gps_btn',
                                locating: _locating,
                                onPressed: _recenterOnGps,
                              ),
                            ),
                            NearbyMapBottomOverlay(
                              loading: _loading,
                              hasShops: shops.isNotEmpty,
                              selectedShop: selectedShop,
                              radiusKm: _radiusKm,
                              radiusFilterActive: _radiusFilterActive,
                              onSelectRadius: _selectRadius,
                              onClearRadius: () =>
                                  setState(() => _radiusFilterActive = false),
                              onClosePreview: () =>
                                  setState(() => _selectedShop = null),
                              onOpenShop: _openShop,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
