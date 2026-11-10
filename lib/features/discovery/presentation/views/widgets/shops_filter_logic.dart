import 'dart:math' show asin, cos, pi, sin, sqrt;

import 'package:latlong2/latlong.dart' as ll;

import '../../../domain/entities/shop_entity.dart';

/// Verification filter shared by the Shops tab map and list views —
/// one filter state, so switching views never resets it.
enum ShopVerificationFilter { all, verified, unverified }

/// The app's real verified definition. The `shops` documents carry
/// `verification_status` in {'pending', 'approved', ...} with an
/// `is_verified` bool mirroring approval — there is no 'verified'
/// status value. A shop counts as verified when either signal says
/// so (ShopModel.fromMap derives them consistently).
bool isShopVerified(ShopEntity shop) =>
    shop.isVerified || shop.verificationStatus == 'approved';

/// Pure Shops-tab filter: which shops show for one filter state and
/// one platform-setting value. Pure so the setting behaviour is
/// testable without Firestore.
///
/// - [displayUnverifiedShops] is `platform_settings/global`
///   `displayUnverifiedShops` (default ON). When OFF, unverified
///   shops are hidden from map AND list even when the filter is
///   "all" — the Unverified chip is not offered either.
/// - When ON (default), the filter chooses: all shows every shop
///   (unverified included — never silently hidden by default),
///   verified shows verified only, unverified shows unverified only.
/// - [city] matches `shop_city` case-insensitively; null means all
///   cities.
List<ShopEntity> filterShopsForDisplay({
  required List<ShopEntity> shops,
  required String? city,
  required ShopVerificationFilter verification,
  required bool displayUnverifiedShops,
}) {
  return shops.where((shop) {
    final verified = isShopVerified(shop);
    if (!verified && !displayUnverifiedShops) return false;
    if (city != null &&
        shop.city.toLowerCase() != city.toLowerCase()) {
      return false;
    }
    return switch (verification) {
      ShopVerificationFilter.all => true,
      ShopVerificationFilter.verified => verified,
      ShopVerificationFilter.unverified => !verified,
    };
  }).toList();
}

/// Great-circle distance in kilometres between two coordinates
/// (same haversine as the discovery data source).
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return 2 * earthRadiusKm * asin(sqrt(a));
}

/// Copies of [shops] with `distanceKm` recomputed from [from] and
/// sorted nearest-first. The draggable "you are here" pin re-sorts
/// the map's nearby results from its new position; the stored
/// entities are never mutated.
List<ShopEntity> sortShopsByDistance(
    List<ShopEntity> shops, ll.LatLng from) {
  final sorted = shops
      .map((shop) => shop.withDistance(haversineKm(
            from.latitude,
            from.longitude,
            shop.geoLocation.latitude,
            shop.geoLocation.longitude,
          )))
      .toList();
  sorted.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return sorted;
}
