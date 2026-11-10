import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/core/widgets/verified_badge.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/discovery/presentation/cubit/shops_filter_state.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_map_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_location_prompt_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_shops_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/city_selector_bar.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shop_list_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shops_filter_bar.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Shops tab: the LISTING is the default view; a map button opens
// the full-screen Nearby showrooms map (Pakistan viewport, same
// filters); back returns to the listing. Bounded pumps only — the
// real map starts tile loads that must never hang the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ShopEntity shop(String id, String name, String city, double lat,
      double lng,
      {bool verified = true, bool hasRealLocation = true}) {
    return ShopEntity(
      shopId: id,
      ownerId: 'owner-$id',
      shopName: name,
      phoneNumber: '03000000000',
      address: 'Somewhere, $city',
      city: city,
      geoLocation: GeoPointEntity(lat, lng),
      availableCount: 3,
      isVerified: verified,
      verificationStatus: verified ? 'approved' : 'pending',
      hasRealLocation: hasRealLocation,
    );
  }

  final lahore = shop('lhr', 'Lahore Motors', 'Lahore', 31.5204, 74.3587);
  final karachi = shop('khi', 'Karachi Rentals', 'Karachi', 24.8607,
      67.0011,
      verified: false);
  final multanNoPin =
      shop('mul', 'Multan Cars', 'Multan', 30.1575, 71.5249,
          hasRealLocation: false);

  Future<List<ShopEntity>> allShops() async =>
      [lahore, karachi, multanNoPin];

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Future<void> pumpListing(
    WidgetTester tester, {
    ShopsFilterState? filters,
    Future<bool> Function()? displayUnverified,
    Future<List<ShopEntity>> Function()? loader,
  }) async {
    // Tall surface: all three list cards fit, so counts are stable.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(CustomerShopsView(
      shopsLoader: loader ?? allShops,
      displayUnverifiedLoader: displayUnverified ?? () async => true,
      filterState: filters ?? ShopsFilterState(),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpMap(
    WidgetTester tester, {
    ShopsFilterState? filters,
    bool? isOnline,
  }) async {
    await tester.pumpWidget(wrap(CustomerHomeMapView(
      shopsLoader: allShops,
      displayUnverifiedLoader: () async => true,
      isOnlineOverride: isOnline,
      filterState: filters ?? ShopsFilterState(),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  List<Marker> shopMarkers(WidgetTester tester) {
    final layer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    return layer.markers.where((m) => m.width == 140).toList();
  }

  /// Tap a verification chip (scoped: the same words also appear on
  /// badges and pin labels).
  Future<void> tapFilterChip(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
      of: find.byType(ShopsFilterBar),
      matching: find.text(label),
    ));
    await tester.pump();
  }

  /// Tap a city chip (scoped to the city menu).
  Future<void> tapCityChip(WidgetTester tester, String city) async {
    await tester.tap(find.descendant(
      of: find.byType(CitySelectorBar),
      matching: find.text(city),
    ));
    await tester.pump();
  }

  group('Shops listing (default view)', () {
    testWidgets('listing is the default: cards, no map', (tester) async {
      await pumpListing(tester);
      expect(find.byType(ShopListCard), findsNWidgets(3));
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Lahore Motors'), findsOneWidget);
    });

    testWidgets('default filter shows all shops, unverified included',
        (tester) async {
      await pumpListing(tester);
      expect(find.text('Lahore Motors'), findsOneWidget);
      expect(find.text('Karachi Rentals'), findsOneWidget);
      expect(find.text('Multan Cars'), findsOneWidget);
    });

    testWidgets('every card states Verified/Unverified + fleet count',
        (tester) async {
      await pumpListing(tester);
      final badges = tester.widgetList<VerifiedBadge>(
          find.byType(VerifiedBadge));
      expect(badges.map((b) => b.isVerified).toList(),
          containsAll([true, false]));
      // The unverified card says Unverified, not "Pending Review".
      expect(
        find.descendant(
          of: find.byType(ShopListCard),
          matching: find.text('Unverified'),
        ),
        findsOneWidget,
      );
      expect(find.text('3 cars available'), findsNWidgets(3));
    });

    testWidgets('city filter actually filters the list', (tester) async {
      await pumpListing(tester);
      await tapCityChip(tester, 'Karachi');
      expect(find.text('Karachi Rentals'), findsOneWidget);
      expect(find.text('Lahore Motors'), findsNothing);
    });

    testWidgets('verification filters actually filter', (tester) async {
      await pumpListing(tester);
      await tapFilterChip(tester, 'Verified');
      expect(find.text('Lahore Motors'), findsOneWidget);
      expect(find.text('Karachi Rentals'), findsNothing);
      await tapFilterChip(tester, 'Unverified');
      expect(find.text('Karachi Rentals'), findsOneWidget);
      expect(find.text('Lahore Motors'), findsNothing);
    });

    testWidgets('displayUnverifiedShops OFF hides unverified shops',
        (tester) async {
      await pumpListing(tester,
          displayUnverified: () async => false);
      expect(find.text('Lahore Motors'), findsOneWidget);
      expect(find.text('Karachi Rentals'), findsNothing);
      expect(find.text('Unverified'), findsNothing);
    });

    testWidgets('empty filter shows the honest empty state',
        (tester) async {
      await pumpListing(tester, loader: () async => <ShopEntity>[]);
      expect(find.text('No shops match these filters'), findsOneWidget);
    });

    testWidgets('no GPS permission shows the manual city note',
        (tester) async {
      // No plugin implementation answers in widget tests: the
      // checkPermission Future never completes under the fake clock,
      // so answer it with a mock — 0 = denied — and the manual city
      // note appears. (Probed: plain tests throw MissingPluginException
      // at once; testWidgets hangs the call until a mock answers.)
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => 0);
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
      await pumpListing(tester);
      expect(find.text('Choose a city to browse shops'), findsOneWidget);
    });
  });

  group('Full-screen map', () {
    testWidgets('map starts on the whole of Pakistan', (tester) async {
      await pumpMap(tester);
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCenter.latitude, closeTo(30.5, 0.01));
      expect(map.options.initialCenter.longitude, closeTo(68.25, 0.01));
      expect(map.options.initialZoom, 5.0);
    });

    testWidgets('pins only for shops with real locations',
        (tester) async {
      await pumpMap(tester);
      // Lahore + Karachi have pins; Multan (no stored location) does not.
      expect(shopMarkers(tester).length, 2);
    });

    testWidgets('city menu centres the map AND applies the filter',
        (tester) async {
      final filters = ShopsFilterState();
      await pumpMap(tester, filters: filters);
      await tapCityChip(tester, 'Karachi');
      await tester.pump(const Duration(milliseconds: 100));
      expect(filters.city, 'Karachi');
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      expect(controller.camera.center.latitude, closeTo(24.86, 0.5));
      expect(controller.camera.center.longitude, closeTo(67.0, 0.5));
      expect(shopMarkers(tester).length, 1);
    });

    testWidgets('offline map says so honestly', (tester) async {
      await pumpMap(tester, isOnline: false);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Map unavailable offline — the list still works'),
          findsOneWidget);
    });

    testWidgets('tapping a pin opens the shop page', (tester) async {
      var opened = '';
      // Tall surface: the preview card must not cover the pin.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(CustomerHomeMapView(
        shopsLoader: allShops,
        displayUnverifiedLoader: () async => true,
        filterState: ShopsFilterState(),
        onShopSelected: (s) => opened = s.shopId,
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Tapping a pin selects it and shows the preview card — the
      // preview's View Fleet button opens the shop page. Tap the
      // Karachi pin (not the auto-selected Lahore one) so the test
      // proves the tap switched the preview: opened must be 'khi'.
      await tester.tap(find.descendant(
        of: find.byType(MarkerLayer),
        matching: find.text('Karachi Rentals'),
      ));
      await tester.pump();
      await tester.tap(find.text('View Fleet'));
      await tester.pump();
      expect(opened, 'khi');
    });
  });

  group('Listing <-> map flow with shared filters', () {
    late GoRouter router;
    late ShopsFilterState filters;

    GoRouter buildRouter() {
      filters = ShopsFilterState();
      return GoRouter(
        initialLocation: RouteNames.customerShops,
        routes: [
          GoRoute(
            path: RouteNames.customerShops,
            builder: (context, state) => CustomerShopsView(
              shopsLoader: allShops,
              displayUnverifiedLoader: () async => true,
              filterState: filters,
              onShopSelected: (_) {},
            ),
          ),
          GoRoute(
            path: RouteNames.customerShopsMap,
            builder: (context, state) => CustomerHomeMapView(
              shopsLoader: allShops,
              displayUnverifiedLoader: () async => true,
              filterState: filters,
              onShopSelected: (_) {},
            ),
          ),
        ],
      );
    }

    Future<void> pumpRouter(WidgetTester tester) async {
      router = buildRouter();
      // Tall surface: all three list cards fit on return.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('map button opens the map; back returns to the listing',
        (tester) async {
      await pumpRouter(tester);
      expect(find.byType(ShopListCard), findsNWidgets(3));
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Nearby Showrooms'), findsOneWidget);
      // Back arrow returns to the listing (a sub-screen, no tab bar).
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ShopListCard), findsNWidgets(3));
      router.dispose();
    });

    testWidgets('filter set in the listing is still applied on the map',
        (tester) async {
      await pumpRouter(tester);
      await tapCityChip(tester, 'Karachi');
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(shopMarkers(tester).length, 1);
      router.dispose();
    });

    testWidgets('filter set on the map is still applied in the listing',
        (tester) async {
      await pumpRouter(tester);
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tapFilterChip(tester, 'Unverified');
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Karachi Rentals'), findsOneWidget);
      expect(find.text('Lahore Motors'), findsNothing);
      router.dispose();
    });
  });

  group('Draggable user pin on the map', () {
    testWidgets('dragging the pin re-sorts; shop pins do not move',
        (tester) async {
      final filters = ShopsFilterState()
        ..userPoint = const ll.LatLng(31.5204, 74.3587);
      await pumpMap(tester, filters: filters);
      // Nearest to Lahore on load: the preview shows Lahore Motors.
      expect(find.text('Lahore Motors'), findsWidgets);
      final before = shopMarkers(tester).map((m) => m.point).toList();

      // Drag the user pin west + south, towards Karachi.
      final pinCenter =
          tester.getCenter(find.byIcon(Icons.my_location_rounded));
      await tester.dragFrom(pinCenter, const Offset(-167, 150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(filters.userPoint!.longitude, lessThan(70));
      expect(filters.userPoint!.latitude, lessThan(28));
      // Re-sorted: Karachi is now nearest, its preview shows.
      expect(find.text('Karachi Rentals'), findsWidgets);
      // Shop pins never moved (same set of points; their order in
      // the layer follows the distance sort, so compare as a set).
      final after = shopMarkers(tester).map((m) => m.point).toList();
      expect(after.toSet(), before.toSet());
      expect(after.length, before.length);
    });
  });

  group('Set-location flow pin', () {
    testWidgets('dragging the centre pin moves the chosen point',
        (tester) async {
      await tester.pumpWidget(
          wrap(const CustomerLocationPromptView()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Gulberg III, Lahore'), findsOneWidget);
      final pinCenter =
          tester.getCenter(find.byIcon(Icons.location_on_rounded));
      await tester.dragFrom(pinCenter, const Offset(60, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // The chosen point followed the drag: coordinates, not the
      // city area label any more.
      expect(find.text('Gulberg III, Lahore'), findsNothing);
      expect(find.textContaining('°N'), findsOneWidget);
    });
  });
}
