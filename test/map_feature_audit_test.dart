import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/app_map_tile_layer.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/discovery/presentation/cubit/shops_filter_state.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_map_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/map_shop_preview_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shops_filter_logic.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shops_tab_data.dart';
import 'package:rentalhub/features/owner/presentation/widgets/onboarding/shop_location_step_widget.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

ShopEntity _shop({
  required String id,
  required String name,
  required double lat,
  required double lng,
  String city = 'Lahore',
  double distanceKm = 0,
}) {
  return ShopEntity(
    shopId: id,
    ownerId: 'owner-$id',
    shopName: name,
    address: 'Main Blvd, $city',
    city: city,
    phoneNumber: '03001234567',
    geoLocation: GeoPointEntity(lat, lng),
    isVerified: true,
    verificationStatus: 'approved',
    distanceKm: distanceKm,
    hasRealLocation: true,
    hasRealDistance: distanceKm > 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Map Audit — Pure Logic', () {
    test('filterShopsWithinRadius keeps only shops within selected km', () {
      final shops = [
        _shop(id: 'near', name: 'Near Shop', lat: 31.52, lng: 74.36, distanceKm: 1.5),
        _shop(id: 'mid', name: 'Mid Shop', lat: 31.55, lng: 74.39, distanceKm: 4.2),
        _shop(id: 'far', name: 'Far Shop', lat: 31.70, lng: 74.50, distanceKm: 18.0),
      ];

      expect(filterShopsWithinRadius(shops, null).length, 3);
      expect(filterShopsWithinRadius(shops, 0).length, 3);
      expect(
        filterShopsWithinRadius(shops, 3.0).map((s) => s.shopId).toList(),
        ['near'],
      );
      expect(
        filterShopsWithinRadius(shops, 5.0).map((s) => s.shopId).toList(),
        ['near', 'mid'],
      );
    });

    test('nearestKnownCity resolves Lahore GPS coordinates to Lahore', () {
      expect(ShopsTabData.nearestKnownCity(31.5204, 74.3587), 'Lahore');
      expect(ShopsTabData.nearestKnownCity(24.8607, 67.0011), 'Karachi');
      expect(ShopsTabData.nearestKnownCity(33.6844, 73.0479), 'Islamabad');
    });
  });

  group('Map Audit — UI, Semantics & Dark Mode', () {
    testWidgets('MapShopPreviewCard renders Directions and dismissible Close button',
        (tester) async {
      var closed = false;
      final shop = _shop(
        id: 's1',
        name: 'Royal Motors',
        lat: 31.5204,
        lng: 74.3587,
        distanceKm: 2.1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MapShopPreviewCard(
              shop: shop,
              positioned: false,
              onClose: () => closed = true,
              onViewShowroom: () {},
            ),
          ),
        ),
      );

      expect(find.text('Royal Motors'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets(
        'CustomerHomeMapView renders GPS FAB, OSM attribution, and filters shops on radius selection',
        (tester) async {
      final filters = ShopsFilterState()
        ..setCity('Lahore')
        ..setUserPoint(const ll.LatLng(31.5204, 74.3587));
      final near = _shop(id: 'near', name: 'Gulberg Cars', lat: 31.5210, lng: 74.3590);
      final far = _shop(id: 'far', name: 'Ring Road Cars', lat: 31.6500, lng: 74.4500);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerHomeMapView(
            filterState: filters,
            isOnlineOverride: true,
            shopsLoader: () async => [near, far],
            displayUnverifiedLoader: () async => true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // OSM attribution & GPS re-center FAB present
      expect(find.byType(AppOsmAttribution), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Both shops visible initially before radius filter is activated
      expect(find.text('Gulberg Cars'), findsOneWidget);
      expect(find.text('Ring Road Cars'), findsOneWidget);

      // Selecting 3 km filters out the ~17 km distant shop
      await tester.tap(find.text('Radius: 3 km'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('3 km'));
      await tester.pump();

      expect(find.text('Gulberg Cars'), findsOneWidget);
      expect(find.text('Ring Road Cars'), findsNothing);
    });

    testWidgets(
        'ShopLocationStepWidget uses bottomCenter marker alignment, OSM attribution, and 48dp expand button',
        (tester) async {
      final mapController = MapController();
      final addressController = TextEditingController();
      addTearDown(() {
        mapController.dispose();
        addressController.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShopLocationStepWidget(
                mapController: mapController,
                shopPin: const ll.LatLng(31.5204, 74.3587),
                onPinChanged: (_) {},
                addressController: addressController,
                selectedCity: 'Lahore',
                onCityChanged: (_) {},
                majorCities: const [
                  {'name': 'Lahore', 'coords': ll.LatLng(31.5204, 74.3587)},
                ],
                isLocating: false,
                onFetchGps: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.single.alignment, Alignment.bottomCenter);
      expect(find.byType(AppOsmAttribution), findsOneWidget);

      final expandBtnSize =
          tester.getSize(find.widgetWithIcon(IconButton, Icons.fullscreen_rounded));
      expect(expandBtnSize.width, greaterThanOrEqualTo(48));
      expect(expandBtnSize.height, greaterThanOrEqualTo(48));
    });
  });
}
