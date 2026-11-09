import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:rentalhub/features/owner/presentation/widgets/fleet/boundary_map_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// 010b boundary map header card: real map when coordinates exist
// and the device is online, deck-style dashed-circle illustration
// otherwise. No Firebase in these tests — the widget must render
// the illustration in the test env without crashing (no DI init,
// no Firestore, no network).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const lahore = ll.LatLng(31.5102, 74.3441);

  Future<void> pumpCard(
    WidgetTester tester, {
    String homeCity = 'Lahore',
    int radiusKm = 40,
    ll.LatLng? initialCenter,
    Future<ll.LatLng?> Function(String shopId)? locationLoader,
    bool? isOnlineOverride,
    VoidCallback? onEdit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: BoundaryMapCard(
                shopId: 'shop-1',
                homeCity: homeCity,
                radiusKm: radiusKm,
                initialCenter: initialCenter,
                locationLoader: locationLoader,
                isOnlineOverride: isOnlineOverride,
                onEdit: onEdit,
              ),
            ),
          ),
        ),
      ),
    );
    // Let the lazy coordinate load (a Future, even when it fails
    // fast) finish. Bounded pumps, not pumpAndSettle: the real map
    // starts tile loads that must never hang the test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  double circleRadius(WidgetTester tester) {
    final layer = tester.widget<CircleLayer>(find.byType(CircleLayer));
    return layer.circles.single.radius;
  }

  group('BoundaryMapCard', () {
    testWidgets('illustration renders when no coordinates are available',
        (tester) async {
      await pumpCard(tester);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.text('Lahore · 40 km'), findsOneWidget);
      expect(
        find.text('Shop location not set — boundary shown as text'),
        findsOneWidget,
      );
    });

    testWidgets('map renders when coordinates are injected', (tester) async {
      await pumpCard(tester, initialCenter: lahore);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(CircleLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(circleRadius(tester), 40000);
      expect(find.text('Lahore · 40 km'), findsOneWidget);
    });

    testWidgets('map renders when the location loader returns coordinates',
        (tester) async {
      await pumpCard(
        tester,
        locationLoader: (_) async => lahore,
      );
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(circleRadius(tester), 40000);
    });

    testWidgets('circle radius follows the radius param', (tester) async {
      await pumpCard(tester, initialCenter: lahore, radiusKm: 40);
      expect(circleRadius(tester), 40000);
      // Same card, boundary edited: re-pump with radius 60.
      await pumpCard(tester, initialCenter: lahore, radiusKm: 60);
      expect(circleRadius(tester), 60000);
      expect(find.text('Lahore · 60 km'), findsOneWidget);
    });

    testWidgets('text shows the city and radius', (tester) async {
      await pumpCard(
        tester,
        homeCity: 'Islamabad',
        radiusKm: 60,
        initialCenter: const ll.LatLng(33.6844, 73.0479),
      );
      expect(find.text('Islamabad · 60 km'), findsOneWidget);
    });

    testWidgets('offline shows the illustration with the offline note',
        (tester) async {
      await pumpCard(
        tester,
        initialCenter: lahore,
        isOnlineOverride: false,
      );
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.text('Map unavailable offline'), findsOneWidget);
      expect(find.text('Lahore · 40 km'), findsOneWidget);
    });

    testWidgets('Edit button appears only with onEdit and calls it',
        (tester) async {
      var tapped = false;
      await pumpCard(tester, onEdit: () => tapped = true);
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      expect(tapped, isTrue);
    });

    testWidgets('no Edit button without onEdit', (tester) async {
      await pumpCard(tester);
      expect(find.text('Edit'), findsNothing);
    });
  });
}
