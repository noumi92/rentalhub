import 'dart:math' show asin, cos, pi, sin, sqrt;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shop_model.dart';

/// B1: real discovery. Reads the `shops` collection from Firestore and
/// returns the shops within [radiusKm] of the customer's location,
/// nearest first, with the distance computed (haversine) from the
/// shop's stored coordinates — never from a stored `distance_km`
/// value, which an owner would have no reason to keep accurate.
///
/// The old version returned 4 hardcoded shops (with invented bank
/// accounts) and filtered on their invented distances. That seeded list
/// is deleted; an empty or unreachable `shops` collection now honestly
/// returns an empty list and the home screen shows its empty state.
///
/// Admin-integration audit (2026-11-10): two platform decisions are
/// honoured here, not just in the Shops tab —
/// - a suspended shop (`suspended: true`, set by the admin panel)
///   never appears, in either path;
/// - unverified shops are included when [includeUnverified] is true.
///   The repository resolves that flag from
///   `platform_settings/global` `displayUnverifiedShops` (default ON),
///   so the admin toggle governs the nearby radar exactly as it
///   governs the Shops tab. Before this fix the radar hard-filtered
///   `!isVerified` and ignored the toggle entirely.
class DiscoveryRemoteDataSource {
  Future<List<ShopModel>> fetchNearbyShops({
    required double radiusKm,
    required double latitude,
    required double longitude,
    bool includeUnverified = true,
  }) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('shops').get();
    final shops = <ShopModel>[];
    for (final doc in snapshot.docs) {
      final shop = ShopModel.fromMap(doc.data(), id: doc.id);
      if (shop.suspended) continue;
      if (!shop.isVerified && !includeUnverified) continue;
      final distanceKm = _haversineKm(
        latitude,
        longitude,
        shop.geoLocation.latitude,
        shop.geoLocation.longitude,
      );
      if (distanceKm > radiusKm) continue;
      // The stored `distance_km` (if any) is ignored: the computed
      // distance is the one the customer sees and sorts by.
      shops.add(ShopModel.fromMap(
        {...doc.data(), 'distance_km': distanceKm},
        id: doc.id,
      ));
    }
    shops.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return shops;
  }

  /// Shops tab: every shop document, not just the verified ones
  /// within a GPS radius — the tab's own city + verified filters do
  /// the narrowing, so unverified shops must be in the list too.
  /// Sorted by city, then name. An empty or unreachable `shops`
  /// collection honestly returns an empty list. Suspended shops are
  /// excluded here (admin-integration audit 2026-11-10): a shop the
  /// admin suspended must not be discoverable in either view.
  Future<List<ShopModel>> fetchAllShops() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('shops').get();
    final shops = snapshot.docs
        .map((doc) => ShopModel.fromMap(doc.data(), id: doc.id))
        .where((shop) => !shop.suspended)
        .toList();
    shops.sort((a, b) {
      final byCity =
          a.city.toLowerCase().compareTo(b.city.toLowerCase());
      return byCity != 0
          ? byCity
          : a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase());
    });
    return shops;
  }

  /// Great-circle distance in kilometres between two coordinates.
  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
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
}
