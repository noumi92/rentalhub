import 'package:geolocator/geolocator.dart';

import '../../../../admin/data/repositories/platform_settings_repository.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/connectivity_service.dart';
import '../../../data/datasources/customer_location_store.dart';
import '../../../data/datasources/discovery_remote_data_source.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../cubit/shops_filter_state.dart';
import 'shops_filter_logic.dart';

/// The outcome of a Shops load: the shops, plus whether the fetch
/// itself failed. A failure is NOT an empty list — the views render
/// [AppErrorState] with retry for it and keep the empty state for a
/// genuinely empty result (FG-5).
class ShopsLoadResult {
  const ShopsLoadResult({required this.shops, required this.loadFailed});

  final List<ShopEntity> shops;
  final bool loadFailed;
}

/// Shared data loading for the Shops listing and the full-screen
/// map, so the two views cannot drift apart: all shops plus the
/// `displayUnverifiedShops` setting, read once into the shared
/// filter state. A failed shops fetch surfaces as
/// [ShopsLoadResult.loadFailed]; only a missing setting defaults ON.
class ShopsTabData {
  static Future<ShopsLoadResult> loadShops({
    required ShopsFilterState filters,
    Future<List<ShopEntity>> Function()? shopsLoader,
    Future<bool> Function()? displayUnverifiedLoader,
  }) async {
    List<ShopEntity> shops = const [];
    var loadFailed = false;
    try {
      shops = await (shopsLoader ??
          DiscoveryRemoteDataSource().fetchAllShops)();
    } catch (_) {
      shops = const [];
      loadFailed = true;
    }
    if (!filters.displayUnverifiedLoaded) {
      try {
        final show = await (displayUnverifiedLoader ??
            PlatformSettingsRepository().displayUnverifiedShops)();
        filters.setDisplayUnverifiedShops(show);
      } catch (_) {
        filters.setDisplayUnverifiedShops(true);
      }
    }
    return ShopsLoadResult(shops: shops, loadFailed: loadFailed);
  }

  /// True when GPS permission is granted. Never throws (widget
  /// tests have no geolocator plugin) — false means the city menu
  /// is the manual entry.
  static Future<bool> locationAvailable() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Same pattern as the owner boundary card: the connectivity
  /// service when DI has one, online otherwise. Offline the map
  /// canvas shows its honest note instead of broken tiles.
  static Future<bool> onlineStatus({bool? override}) async {
    if (override != null) return override;
    try {
      final connectivity = sl<ConnectivityService>();
      await connectivity.start();
      return connectivity.isOnline;
    } catch (_) {
      return true;
    }
  }

  /// The nearest known major city to [latitude]/[longitude], or
  /// null when the point is far from every known city. Pure, so the
  /// nearest-city rule is testable without GPS.
  static String? nearestKnownCity(double latitude, double longitude) {
    String? nearest;
    var nearestKm = double.infinity;
    for (final city in kShopsMajorCities) {
      final km = haversineKm(latitude, longitude,
          city['lat'] as double, city['lng'] as double);
      if (km < nearestKm) {
        nearestKm = km;
        nearest = city['name'] as String;
      }
    }
    // Only pre-select a city the user is plausibly in: beyond 150 km
    // from every known city the honest default is All cities.
    return nearestKm <= 150 ? nearest : null;
  }

  /// True when [city] is one of the known major cities.
  static bool isKnownCity(String city) => kShopsMajorCities.any(
      (c) => (c['name'] as String).toLowerCase() == city.toLowerCase());

  /// PW-5: pre-select a city on the shared filter state — but only
  /// when the user has not picked one yet (`filters.city == null`).
  /// GPS first (nearest known city when permission is granted),
  /// then the saved city from the set-location flow. Never throws
  /// and never overrides an explicit choice; All cities stays one
  /// tap away in the city picker sheet.
  static Future<void> preselectCity(ShopsFilterState filters) async {
    if (filters.city != null) return;
    try {
      if (await locationAvailable()) {
        final position = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 10));
        final nearest = nearestKnownCity(
            position.latitude, position.longitude);
        if (nearest != null) {
          filters.setCity(nearest);
          return;
        }
      }
    } catch (_) {
      // No GPS fix — fall through to the saved city.
    }
    try {
      final stored = await CustomerLocationStore().load();
      final city = stored?.city.trim() ?? '';
      if (city.isNotEmpty && isKnownCity(city)) {
        filters.setCity(city);
      }
    } catch (_) {
      // No saved city — the listing stays on All cities.
    }
  }

  /// PW-4: the cheapest available daily rate per shop (min over its
  /// available cars' `rates.daily24`), keyed by shop id. A shop
  /// with no available cars — or a failed read — simply has no
  /// entry, so the card hides the price line instead of inventing
  /// one. One read per shop; failures never break the list.
  static Future<Map<String, int>> loadMinDailyRates({
    required List<ShopEntity> shops,
    Future<int?> Function(String shopId)? minDailyRateLoader,
  }) async {
    final rates = <String, int>{};
    for (final shop in shops) {
      try {
        final min = await (minDailyRateLoader ??
            _defaultMinDailyRate)(shop.shopId);
        if (min != null) rates[shop.shopId] = min;
      } catch (_) {
        // No price for this shop — the card hides the line.
      }
    }
    return rates;
  }

  static Future<int?> _defaultMinDailyRate(String shopId) async {
    final vehicles = await sl<FleetRemoteDataSource>()
        .getCustomerShopVehicles(shopId);
    final available = vehicles.where((v) => v.status == 'available');
    if (available.isEmpty) return null;
    return available
        .map((v) => v.rates.daily24)
        .reduce((a, b) => a < b ? a : b);
  }
}
