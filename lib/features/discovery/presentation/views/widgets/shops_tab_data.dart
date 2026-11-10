import 'package:geolocator/geolocator.dart';

import '../../../../admin/data/repositories/platform_settings_repository.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/connectivity_service.dart';
import '../../../data/datasources/discovery_remote_data_source.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../cubit/shops_filter_state.dart';

/// Shared data loading for the Shops listing and the full-screen
/// map, so the two views cannot drift apart: all shops plus the
/// `displayUnverifiedShops` setting, read once into the shared
/// filter state. Nothing here ever throws — an unreachable Firestore
/// honestly yields an empty list, and a missing setting defaults ON.
class ShopsTabData {
  static Future<List<ShopEntity>> loadShops({
    required ShopsFilterState filters,
    Future<List<ShopEntity>> Function()? shopsLoader,
    Future<bool> Function()? displayUnverifiedLoader,
  }) async {
    List<ShopEntity> shops = const [];
    try {
      shops = await (shopsLoader ??
          DiscoveryRemoteDataSource().fetchAllShops)();
    } catch (_) {
      shops = const [];
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
    return shops;
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
}
