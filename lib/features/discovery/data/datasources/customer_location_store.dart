import 'package:shared_preferences/shared_preferences.dart';

/// B1: the customer's chosen search location, picked on the location
/// prompt (live GPS or a city) and persisted so the home screen searches
/// from the same place after a restart — instead of the hardcoded
/// "Gulberg III, Lahore" the home header used to claim.
class CustomerLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String area;
  final bool fromGps;

  const CustomerLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.area,
    required this.fromGps,
  });

  /// The default before the customer has picked anything: Lahore, the
  /// same city the location prompt opens on.
  static const defaultLocation = CustomerLocation(
    latitude: 31.5204,
    longitude: 74.3587,
    city: 'Lahore',
    area: 'Gulberg III, Lahore',
    fromGps: false,
  );
}

class CustomerLocationStore {
  static const _latKey = 'customer_lat';
  static const _lngKey = 'customer_lng';
  static const _cityKey = 'customer_city';
  static const _areaKey = 'customer_area';
  static const _gpsKey = 'customer_from_gps';

  Future<void> save(CustomerLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_lngKey, location.longitude);
    await prefs.setString(_cityKey, location.city);
    await prefs.setString(_areaKey, location.area);
    await prefs.setBool(_gpsKey, location.fromGps);
  }

  Future<CustomerLocation?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    if (lat == null || lng == null) return null;
    return CustomerLocation(
      latitude: lat,
      longitude: lng,
      city: prefs.getString(_cityKey) ?? 'Lahore',
      area: prefs.getString(_areaKey) ?? 'Lahore',
      fromGps: prefs.getBool(_gpsKey) ?? false,
    );
  }
}
