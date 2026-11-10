import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../data/datasources/customer_location_store.dart';
import '../../domain/entities/shop_entity.dart';
import '../cubit/shops_filter_state.dart';
import 'widgets/city_selector_bar.dart';
import 'widgets/map_shop_preview_card.dart';
import 'widgets/shops_empty_banner.dart';
import 'widgets/shops_filter_bar.dart';
import 'widgets/shops_filter_logic.dart';
import 'widgets/shops_location_note.dart';
import 'widgets/shops_map_canvas.dart';
import 'widgets/shops_tab_data.dart';
import '../../../../l10n/app_localizations.dart';

/// The full-screen Nearby showrooms map — the ONE customer map
/// screen, reused as the Shops tab's map view (`/customer/shops/map`;
/// the old `/customer/home/map` route still lands here too). It starts
/// on the WHOLE of Pakistan and carries the SAME filters as the Shops
/// listing through the shared [ShopsFilterState]. Pins are real shop
/// locations only, every pin carries its Verified/Unverified status,
/// and tapping a pin shows the shop preview. The "you are here" pin is
/// DRAGGABLE: dragging it re-sorts the nearby shops by distance from
/// its new point (shop pins never move).
class CustomerHomeMapView extends StatefulWidget {
  const CustomerHomeMapView({
    super.key,
    this.shopsLoader,
    this.displayUnverifiedLoader,
    this.isOnlineOverride,
    this.filterState,
    this.onShopSelected,
  });

  /// Test seam: override the Firestore shop read.
  final Future<List<ShopEntity>> Function()? shopsLoader;

  /// Test seam: override the `displayUnverifiedShops` setting read.
  final Future<bool> Function()? displayUnverifiedLoader;

  /// Test seam: force the online/offline decision.
  final bool? isOnlineOverride;

  /// Test seam: the shared filter state (default [ShopsFilterState.shared]).
  final ShopsFilterState? filterState;

  /// Test seam: override the shop-page navigation.
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
  bool _online = true;
  bool? _locationAvailable;
  String? _lastCity;

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
  }

  @override
  void dispose() {
    _filters.removeListener(_onFiltersChanged);
    _mapController.dispose();
    super.dispose();
  }

  /// A city pick recentres this map; dropping the previewed shop clears it.
  void _onFiltersChanged() {
    if (_filters.city != _lastCity) {
      _lastCity = _filters.city;
      _mapController.move(_filters.mapCenter, _filters.mapZoom);
    }
    final filtered = _filters.apply(_shops);
    // Compare by id: the preview holds a distance-sorted copy whose
    // recomputed distanceKm differs from the stored entity, so
    // Equatable contains() would wrongly clear it on every change.
    if (_selectedShop != null &&
        !filtered.any((s) => s.shopId == _selectedShop!.shopId)) {
      setState(() => _selectedShop = null);
    }
  }

  Future<void> _loadShops() async {
    final shops = await ShopsTabData.loadShops(
      filters: _filters,
      shopsLoader: widget.shopsLoader,
      displayUnverifiedLoader: widget.displayUnverifiedLoader,
    );
    if (!mounted) return;
    setState(() {
      _shops = shops;
      _loading = false;
      if (_selectedShop == null) _selectNearest();
    });
  }

  /// The stored location (from the set-location flow) places the user
  /// pin on first open; a drag after that wins over it.
  Future<void> _loadStoredLocation() async {
    if (_filters.userPoint != null) return;
    try {
      final stored = await CustomerLocationStore().load();
      if (!mounted || stored == null) return;
      _filters.setUserPoint(ll.LatLng(stored.latitude, stored.longitude));
    } catch (_) {
      // No stored location — the pin falls back to the map centre.
    }
  }

  /// The point distances sort from: the dragged pin, else the map centre.
  ll.LatLng get _userPoint => _filters.userPoint ?? _filters.mapCenter;

  List<ShopEntity> _sortedShops() =>
      sortShopsByDistance(_filters.apply(_shops), _userPoint);

  void _selectNearest() {
    final sorted = _sortedShops();
    if (sorted.isNotEmpty) _selectedShop = sorted.first;
  }

  void _onUserPointDragEnd(ll.LatLng point) {
    final sorted = _sortedShops();
    if (sorted.isEmpty) return;
    if (_selectedShop?.shopId != sorted.first.shopId) {
      setState(() => _selectedShop = sorted.first);
    }
  }

  Future<void> _checkLocation() async {
    final available = await ShopsTabData.locationAvailable();
    if (!mounted) return;
    setState(() => _locationAvailable = available);
  }

  Future<void> _checkOnline() async {
    final online =
        await ShopsTabData.onlineStatus(override: widget.isOnlineOverride);
    if (!mounted) return;
    setState(() => _online = online);
  }

  void _selectCity(Map<String, dynamic> city) {
    _filters.setCity(
        city['all'] == true ? null : city['name'] as String);
  }

  void _openShop(ShopEntity shop) {
    if (widget.onShopSelected != null) {
      widget.onShopSelected!.call(shop);
    } else {
      context.push(
        RouteNames.customerShopDetail.replaceFirst(':shopId', shop.shopId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _filters,
      builder: (context, _) {
        // Filtered AND distance-sorted from the user pin, nearest first.
        final shops = _sortedShops();
        final selectedShop = _selectedShop;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                MinimalAppBar(
                  title: l10n.homeNearbyShowrooms,
                  subtitle: l10n.mapTapMarker(
                      _filters.city ?? l10n.shops_allCities),
                  onBack: () => context.pop(),
                ),
                CitySelectorBar(
                  majorCities: shopsCityMenuEntries(l10n),
                  selectedCity: _filters.city ?? l10n.shops_allCities,
                  onSelectCity: _selectCity,
                ),
                ShopsFilterBar(
                  verification: _filters.verification,
                  onVerificationChanged: _filters.setVerification,
                  showUnverifiedFilter: _filters.displayUnverifiedShops,
                ),
                if (_locationAvailable == false)
                  ShopsLocationNote(text: l10n.shops_chooseCity),
                Expanded(
                  child: Stack(
                    children: [
                      ShopsMapCanvas(
                        mapController: _mapController,
                        shops: shops,
                        isOnline: _online,
                        onShopSelected: (shop) =>
                            setState(() => _selectedShop = shop),
                        initialCenter: _filters.mapCenter,
                        initialZoom: _filters.mapZoom,
                        userPoint: _userPoint,
                        onUserPointChanged: _filters.setUserPoint,
                        onUserPointChangeEnd: _onUserPointDragEnd,
                      ),
                      if (_loading)
                        const Center(child: CircularProgressIndicator()),
                      if (!_loading && shops.isEmpty)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: ShopsEmptyBanner(
                              text: l10n.shops_emptyTitle),
                        )
                      else if (selectedShop != null)
                        MapShopPreviewCard(
                          shop: selectedShop,
                          onViewShowroom: () => _openShop(selectedShop),
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
