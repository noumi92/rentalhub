import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shops_map_canvas.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Draggable "you are here" pin: dragging it moves the user point
// (the map re-sorts from it) while shop pins stay exactly where
// they are. Bounded pumps only — the real map starts tile loads
// that must never hang the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ShopEntity shop(String id, String name, double lat, double lng,
      {bool verified = true}) {
    return ShopEntity(
      shopId: id,
      ownerId: 'owner-$id',
      shopName: name,
      phoneNumber: '03000000000',
      address: 'Somewhere',
      city: 'Lahore',
      geoLocation: GeoPointEntity(lat, lng),
      isVerified: verified,
      verificationStatus: verified ? 'approved' : 'pending',
    );
  }

  List<Marker> shopMarkers(WidgetTester tester) {
    final layer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    return layer.markers.where((m) => m.width == 140).toList();
  }

  testWidgets('dragging the user pin moves it; shop pins do not move',
      (tester) async {
    final controller = MapController();
    final lahore = shop('lhr', 'Lahore Motors', 31.5204, 74.3587);
    final karachi = shop('khi', 'Karachi Rentals', 24.8607, 67.0011,
        verified: false);
    final userStart = const ll.LatLng(31.5204, 74.3587);
    final movedPoints = <ll.LatLng>[];
    var dragEnded = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: ShopsMapCanvas(
              mapController: controller,
              shops: [lahore, karachi],
              isOnline: true,
              onShopSelected: (_) {},
              userPoint: userStart,
              onUserPointChanged: movedPoints.add,
              onUserPointChangeEnd: (_) => dragEnded = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final before = shopMarkers(tester).map((m) => m.point).toList();
    expect(before.length, 2);
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

    // Drag the user pin east: longitude must grow, latitude ~same.
    await tester.drag(
      find.byIcon(Icons.my_location_rounded),
      const Offset(60, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(movedPoints, isNotEmpty);
    expect(movedPoints.last.longitude,
        greaterThan(userStart.longitude));
    expect(
        (movedPoints.last.latitude - userStart.latitude).abs(),
        lessThan(0.5));
    expect(dragEnded, isTrue);

    // The map itself did not pan: camera centre is unchanged.
    expect(controller.camera.center.latitude,
        closeTo(ShopsMapCanvas.pakistanCenter.latitude, 0.01));
    expect(controller.camera.center.longitude,
        closeTo(ShopsMapCanvas.pakistanCenter.longitude, 0.01));

    // Shop pins are fixed: same points as before the drag.
    final after = shopMarkers(tester).map((m) => m.point).toList();
    expect(after, before);
  });

  testWidgets('pins carry Verified/Unverified text', (tester) async {
    final controller = MapController();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: ShopsMapCanvas(
              mapController: controller,
              shops: [
                shop('lhr', 'Lahore Motors', 31.5204, 74.3587),
                shop('khi', 'Karachi Rentals', 24.8607, 67.0011,
                    verified: false),
              ],
              isOnline: true,
              onShopSelected: (_) {},
              userPoint: const ll.LatLng(30.5, 68.25),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Unverified'), findsOneWidget);
  });

  testWidgets('offline shows the honest note, no map', (tester) async {
    final controller = MapController();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: ShopsMapCanvas(
              mapController: controller,
              shops: const [],
              isOnline: false,
              onShopSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(FlutterMap), findsNothing);
    expect(
        find.text('Map unavailable offline — the list still works'),
        findsOneWidget);
  });
}
