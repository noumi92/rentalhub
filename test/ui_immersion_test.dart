// Phase D (D2/D3) — immersion tests: SafeArea coverage, responsive
// two-column layouts at phone / tablet widths, and the edge-to-edge
// system-inset smoke test.
//
// The local PNG assets are 0-byte files (a download artifact — the
// real assets decode fine on a phone / in CI), so any test that pumps
// a card with an Image.asset and no errorBuilder would trip on
// "Invalid image data". The fleet tests below wrap the view in a
// [_TestAssetBundle] that serves a valid 1x1 transparent PNG for
// every asset key (with a real encoded asset manifest), so the layout
// is what gets tested, not the broken local files.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/utils/responsive.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_shops_view.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_vehicle_calendar_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

/// The 1x1 transparent PNG (the canonical `kTransparentImage` bytes —
/// this SDK's flutter_test does not export the constant).
const _kTransparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// Every image asset the tests below render (fleet cards + shop banners).
const _kTestAssets = [
  'assets/images/honda_civic_hero.png',
  'assets/images/toyota_corolla.png',
  'assets/images/red_civic.png',
  'assets/images/white_sedan_hero.png',
  'assets/images/showroom_banner_1.jpg',
  'assets/images/showroom_banner_2.jpg',
];

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return ByteData.view(Uint8List.fromList(_kTransparentPng).buffer);
  }

  @override
  Future<T> loadStructuredBinaryData<T>(
      String key, FutureOr<T> Function(ByteData data) parser) async {
    if (key == 'AssetManifest.bin') {
      final manifest = <String, Object>{
        for (final asset in _kTestAssets)
          asset: [
            {'asset': asset, 'dpr': 1.0},
          ],
      };
      final encoded = const StandardMessageCodec().encodeMessage(manifest)!;
      return parser(encoded);
    }
    return super.loadStructuredBinaryData(key, parser);
  }
}

ShopEntity _shop(int i) => ShopEntity(
      shopId: 'shop-$i',
      ownerId: 'owner-$i',
      shopName: 'Al-Madina Rent a Car $i',
      phoneNumber: '0300-123456$i',
      address: 'Main Boulevard, Gulberg',
      city: 'Lahore',
      geoLocation: const GeoPointEntity(31.5204, 74.3587),
      distanceKm: 1.0 + i,
    );

VehicleEntity _vehicle(int i, {String shopId = 'shop-1'}) => VehicleEntity(
      vehicleId: 'v-test-$i',
      shopId: shopId,
      make: const ['Honda', 'Toyota', 'Suzuki', 'Kia'][i % 4],
      model: const ['Civic Oriel', 'Corolla Grande', 'Alto VXL', 'Sportage'][i % 4],
      year: 2021 + i,
      plateNumber: 'LEA-100$i',
      rates: VehicleRatesEntity(daily24: 9000 + i * 500),
    );

/// Pumps [screen] at one width through the overflow harness (which
/// asserts no RenderFlex overflow) and returns the tester for the
/// caller's layout assertions.
Future<void> _pumpAtWidth({
  required WidgetTester tester,
  required Widget screen,
  required double width,
}) async {
  await TestHarness.pumpScreenWithOverflowCheck(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    tester: tester,
    screen: DefaultAssetBundle(
      bundle: _TestAssetBundle(),
      child: screen,
    ),
    width: width,
    height: 844,
    textScale: 1.0,
    theme: AppTheme.lightTheme,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('D2: SafeArea coverage (static scan)', () {
    test('all 10 tab roots + shop detail + documents have a SafeArea', () {
      const views = [
        'lib/features/discovery/presentation/views/customer_home_view.dart',
        'lib/features/customer/presentation/views/customer_bookings_view.dart',
        'lib/features/customer/presentation/views/customer_wallet_view.dart',
        'lib/features/customer/presentation/views/customer_support_view.dart',
        'lib/features/customer/presentation/views/customer_profile_view.dart',
        'lib/features/owner/presentation/views/owner_dashboard_view.dart',
        'lib/features/owner/presentation/views/owner_fleet_view.dart',
        'lib/features/owner/presentation/views/owner_booking_requests_view.dart',
        'lib/features/owner/presentation/views/owner_customers_list_view.dart',
        'lib/features/owner/presentation/views/owner_settings_view.dart',
        'lib/features/discovery/presentation/views/shop_detail_view.dart',
        'lib/features/trust/presentation/views/customer_documents_view.dart',
      ];
      final missing = <String>[];
      for (final path in views) {
        if (!File(path).readAsStringSync().contains('SafeArea')) {
          missing.add(path);
        }
      }
      expect(missing, isEmpty,
          reason: 'Views without SafeArea (edge-to-edge needs one):\n'
              '${missing.join('\n')}');
    });
  });

  group('D3: responsive size classes', () {
    testWidgets('windowSizeClassOf splits at 600 / 840', (tester) async {
      for (final (width, expected) in [
        (390.0, WindowSizeClass.compact),
        (599.0, WindowSizeClass.compact),
        (600.0, WindowSizeClass.medium),
        (700.0, WindowSizeClass.medium),
        (839.0, WindowSizeClass.medium),
        (840.0, WindowSizeClass.expanded),
        (1100.0, WindowSizeClass.expanded),
      ]) {
        tester.view.physicalSize = Size(width * 2, 1688);
        tester.view.devicePixelRatio = 2.0;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return Text(windowSizeClassOf(context).name);
              },
            ),
          ),
        );
        expect(find.text(expected.name), findsOneWidget);
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

  group('D3: Home shop list at phone / tablet widths', () {
    testWidgets('390px shows one column', (tester) async {
      // The list lives in the Shops view's scroll view in the app, so
      // pump it in one here too — the bare list is taller than the
      // viewport.
      await _pumpAtWidth(
        tester: tester,
        screen: SingleChildScrollView(
          child: HomeShopList(
            shops: [_shop(1), _shop(2), _shop(3), _shop(4)],
            onShopSelected: (_) {},
          ),
        ),
        width: 390,
      );
      expect(find.byKey(const Key('home-shop-two-columns')), findsNothing);
      expect(find.text('Al-Madina Rent a Car 1'), findsOneWidget);
    });

    testWidgets('700px shows two columns', (tester) async {
      await _pumpAtWidth(
        tester: tester,
        screen: SingleChildScrollView(
          child: HomeShopList(
            shops: [_shop(1), _shop(2), _shop(3), _shop(4)],
            onShopSelected: (_) {},
          ),
        ),
        width: 700,
      );
      expect(find.byKey(const Key('home-shop-two-columns')), findsOneWidget);
      expect(find.text('Al-Madina Rent a Car 4'), findsOneWidget);
    });

    testWidgets('1100px shows two columns', (tester) async {
      await _pumpAtWidth(
        tester: tester,
        screen: SingleChildScrollView(
          child: HomeShopList(
            shops: [_shop(1), _shop(2), _shop(3), _shop(4)],
            onShopSelected: (_) {},
          ),
        ),
        width: 1100,
      );
      expect(find.byKey(const Key('home-shop-two-columns')), findsOneWidget);
    });

    testWidgets('full Home view has no overflow at 390 / 700 / 1100',
        (tester) async {
      for (final width in [390.0, 700.0, 1100.0]) {
        await _pumpAtWidth(
          tester: tester,
          screen: const CustomerHomeView(),
          width: width,
        );
        expect(find.text('Find Verified Rental Shops'), findsOneWidget);
      }
    });
  });

  group('D3: Fleet list at phone / tablet widths', () {
    Future<void> seedFleet() async {
      final ds = sl<FleetRemoteDataSource>();
      for (var i = 0; i < 4; i++) {
        await ds.addVehicle(shopId: 'shop-1', vehicle: _vehicle(i));
      }
    }

    testWidgets('390px shows one column', (tester) async {
      await seedFleet();
      await _pumpAtWidth(
        tester: tester,
        screen: const OwnerFleetView(),
        width: 390,
      );
      expect(find.byKey(const Key('fleet-two-columns')), findsNothing);
      expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
    });

    testWidgets('700px shows two columns', (tester) async {
      await seedFleet();
      await _pumpAtWidth(
        tester: tester,
        screen: const OwnerFleetView(),
        width: 700,
      );
      expect(find.byKey(const Key('fleet-two-columns')), findsOneWidget);
      expect(find.text('Kia Sportage 2024'), findsOneWidget);
    });

    testWidgets('1100px shows two columns', (tester) async {
      await seedFleet();
      await _pumpAtWidth(
        tester: tester,
        screen: const OwnerFleetView(),
        width: 1100,
      );
      expect(find.byKey(const Key('fleet-two-columns')), findsOneWidget);
    });
  });

  group('D3: Dashboard + Calendar at phone / tablet widths', () {
    testWidgets('Dashboard: one column at 390, two at 700 / 1100',
        (tester) async {
      await _pumpAtWidth(
        tester: tester,
        screen: const OwnerDashboardView(shopId: 'shop-1'),
        width: 390,
      );
      expect(find.byKey(const Key('dashboard-two-columns')), findsNothing);
      expect(find.text('Showroom Revenue & Operations'), findsOneWidget);

      await _pumpAtWidth(
        tester: tester,
        screen: const OwnerDashboardView(shopId: 'shop-1'),
        width: 700,
      );
      expect(find.byKey(const Key('dashboard-two-columns')), findsOneWidget);

      await _pumpAtWidth(
        tester: tester,
        screen: const OwnerDashboardView(shopId: 'shop-1'),
        width: 1100,
      );
      expect(find.byKey(const Key('dashboard-two-columns')), findsOneWidget);
    });

    testWidgets('Calendar: one column at 390, two at 700 / 1100',
        (tester) async {
      final vehicle = _vehicle(0);
      await _pumpAtWidth(
        tester: tester,
        screen: OwnerVehicleCalendarView(vehicle: vehicle),
        width: 390,
      );
      expect(find.byKey(const Key('calendar-two-columns')), findsNothing);
      expect(find.text('Booking Calendar'), findsOneWidget);

      await _pumpAtWidth(
        tester: tester,
        screen: OwnerVehicleCalendarView(vehicle: vehicle),
        width: 700,
      );
      expect(find.byKey(const Key('calendar-two-columns')), findsOneWidget);
      expect(find.text('Tap a day to see its bookings.'), findsOneWidget);

      await _pumpAtWidth(
        tester: tester,
        screen: OwnerVehicleCalendarView(vehicle: vehicle),
        width: 1100,
      );
      expect(find.byKey(const Key('calendar-two-columns')), findsOneWidget);
    });
  });

  group('D2: edge-to-edge smoke test', () {
    testWidgets('tab root with notch + gesture-bar insets has no overflow',
        (tester) async {
      // A notched phone: 47dp status bar, 34dp gesture bar.
      // FakeViewPadding takes PHYSICAL pixels, and this pump runs at
      // DPR 2.0 (780x1688 physical = 390x844 logical) — so the inset
      // values are doubled to 94 / 68 physical. `padding` (not just
      // `viewPadding`) is what MediaQuery reads: TestFlutterView keeps
      // the two overrides independent, so setting viewPadding alone
      // leaves MediaQuery.padding at 0 and the bar would sit under
      // the notch.
      tester.view.viewPadding =
          const FakeViewPadding(top: 94, bottom: 68);
      tester.view.padding =
          const FakeViewPadding(top: 94, bottom: 68);
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.lightTheme,
          home: const CustomerHomeView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Find Verified Rental Shops'), findsOneWidget);
      // The header clears the notch: its title is fully visible, not
      // clipped under the status bar.
      final title = tester.getTopLeft(find.text('Find Verified Rental Shops'));
      expect(title.dy, greaterThanOrEqualTo(47));
    });
  });
}
