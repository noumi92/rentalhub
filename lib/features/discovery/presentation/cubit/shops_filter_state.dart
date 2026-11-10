import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../domain/entities/shop_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../views/widgets/shops_filter_logic.dart';

/// The shared Shops filter state: one object, one filter state, used
/// by BOTH the Shops listing ([CustomerShopsView]) and the full-screen
/// map ([CustomerHomeMapView]). The two views live in different
/// routes — the listing is the Shops tab root, the map is the
/// branch-internal sub-screen `/customer/shops/map`, built by the
/// router with no arguments — so the state cannot travel through the
/// navigation: both views read [shared] by default (tests inject
/// their own instance). Setting a filter in either view notifies the
/// other; switching views never resets the filters.
///
/// The map starts on the whole of Pakistan ([pakistanCenter],
/// [pakistanZoom]); picking a city centres it on that city.
class ShopsFilterState extends ChangeNotifier {
  ShopsFilterState();

  /// The app-wide instance both Shops views read by default.
  static final ShopsFilterState shared = ShopsFilterState();

  /// Selected city, or null for all cities. Matches `shop_city`
  /// case-insensitively; never a GPS coordinate.
  String? city;

  ShopVerificationFilter verification = ShopVerificationFilter.all;

  /// `platform_settings/global` `displayUnverifiedShops` (default
  /// ON). When OFF, unverified shops are hidden in both views.
  bool displayUnverifiedShops = true;

  /// True once the platform setting has been read (either view may
  /// do the read; the other then skips its own).
  bool displayUnverifiedLoaded = false;

  /// The draggable "you are here" pin on the full-screen map, or
  /// null until it is placed. Lives here (not in the map view's
  /// state) so a drag survives closing and reopening the map. The
  /// map falls back to [mapCenter] while it is null.
  ll.LatLng? userPoint;

  void setUserPoint(ll.LatLng value) {
    if (userPoint == value) return;
    userPoint = value;
    notifyListeners();
  }

  void setCity(String? value) {
    if (city == value) return;
    city = value;
    notifyListeners();
  }

  void setVerification(ShopVerificationFilter value) {
    if (verification == value) return;
    verification = value;
    notifyListeners();
  }

  void setDisplayUnverifiedShops(bool value) {
    displayUnverifiedLoaded = true;
    if (displayUnverifiedShops == value) return;
    displayUnverifiedShops = value;
    notifyListeners();
  }

  List<ShopEntity> apply(List<ShopEntity> shops) =>
      filterShopsForDisplay(
        shops: shops,
        city: city,
        verification: verification,
        displayUnverifiedShops: displayUnverifiedShops,
      );

  /// Map centre for the current city filter, or the whole-Pakistan
  /// centre when no city is picked.
  ll.LatLng get mapCenter =>
      city == null ? pakistanCenter : (cityCenter(city!) ?? pakistanCenter);

  /// Map zoom for the current city filter: Pakistan-wide, or
  /// city-close when a city is picked.
  double get mapZoom => city == null ? pakistanZoom : 10.0;
}

/// Whole-Pakistan viewport: bounds roughly lat 23.5–37.5,
/// lng 61–75.5.
const pakistanCenter = ll.LatLng(30.5, 68.25);
const pakistanZoom = 5.0;

/// The major cities the app knows, with their centres (same
/// coordinates as the location prompt for the seven it lists).
/// City centres only — never shop coordinates.
const List<Map<String, dynamic>> kShopsMajorCities = [
  {'name': 'Lahore', 'lat': 31.5204, 'lng': 74.3587},
  {'name': 'Karachi', 'lat': 24.8607, 'lng': 67.0011},
  {'name': 'Islamabad', 'lat': 33.6844, 'lng': 73.0479},
  {'name': 'Rawalpindi', 'lat': 33.5651, 'lng': 73.0169},
  {'name': 'Faisalabad', 'lat': 31.4504, 'lng': 73.1350},
  {'name': 'Multan', 'lat': 30.1575, 'lng': 71.5249},
  {'name': 'Peshawar', 'lat': 34.0151, 'lng': 71.5249},
  {'name': 'Quetta', 'lat': 30.1798, 'lng': 66.9750},
  {'name': 'Hyderabad', 'lat': 25.3960, 'lng': 68.3578},
  {'name': 'Sialkot', 'lat': 32.4945, 'lng': 74.5229},
  {'name': 'Bahawalpur', 'lat': 29.3544, 'lng': 71.6911},
];

/// Centre of [cityName], or null when the app does not know it.
ll.LatLng? cityCenter(String cityName) {
  for (final city in kShopsMajorCities) {
    if ((city['name'] as String).toLowerCase() ==
        cityName.toLowerCase()) {
      return ll.LatLng(city['lat'] as double, city['lng'] as double);
    }
  }
  return null;
}

/// City-menu entries for [CitySelectorBar]: "All cities" first
/// (Pakistan-wide), then the major cities.
List<Map<String, dynamic>> shopsCityMenuEntries(AppLocalizations l10n) {
  return [
    {
      'name': l10n.shops_allCities,
      'lat': pakistanCenter.latitude,
      'lng': pakistanCenter.longitude,
      'all': true,
    },
    ...kShopsMajorCities,
  ];
}
