// E1 (Phase E, worker 1): quick-action tiles + MaskedValue.
//
// NOTE on the file name: this file is deliberately
// `ui_phase_d_immersion_test.dart`, not `ui_immersion_test.dart` —
// the latter is Phase D's file (headers / SafeArea / responsive).
// This file covers only E1: the tiles and the masked value.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/core/widgets/app_state_views.dart';
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'package:rentalhub/core/widgets/masked_value.dart';
import 'package:rentalhub/core/widgets/quick_action_tiles.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/views/owner_payment_accounts_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_bookings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_profile_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_support_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';
import 'package:rentalhub/features/customer/presentation/widgets/profile_cnic_row.dart';
import 'package:rentalhub/features/customer/presentation/widgets/support_faq_list.dart';
import 'package:rentalhub/features/customer/data/services/customer_wallet_service.dart';
import 'package:rentalhub/features/customer/presentation/widgets/wallet_ledger.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:rentalhub/features/discovery/domain/usecases/get_nearby_shops_usecase.dart';
import 'package:rentalhub/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/shop_cars_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/shop_detail_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/empty_radar_state.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shop_vehicle_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/vehicle_hero_card.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/presentation/cubit/fleet_state.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_body.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

class _FakeDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<List<ShopEntity>> getNearbyShops({
    required double radiusKm,
    required double latitude,
    required double longitude,
  }) async =>
      const [
        ShopEntity(
          shopId: 'shop-1',
          ownerId: 'owner-1',
          shopName: 'Al-Madina Rent a Car',
          phoneNumber: '03001234567',
          address: 'Main Boulevard',
          city: 'Lahore',
          geoLocation: GeoPointEntity(31.52, 74.35),
        ),
      ];
}

Widget _stubPage(String label) => Scaffold(
      body: Center(child: Text(label)),
    );

GoRouter _e1Router({required String initialLocation}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: RouteNames.customerHome,
          builder: (_, __) => const CustomerHomeView(),
        ),
        GoRoute(
          path: RouteNames.customerHomeMap,
          builder: (_, __) => _stubPage('stub-map'),
        ),
        GoRoute(
          path: RouteNames.customerBookings,
          builder: (_, __) => _stubPage('stub-bookings'),
        ),
        GoRoute(
          path: RouteNames.customerSos,
          builder: (_, __) => _stubPage('stub-sos'),
        ),
        GoRoute(
          path: RouteNames.customerShops,
          builder: (_, __) => _stubPage('stub-shops'),
        ),
        GoRoute(
          path: RouteNames.customerWallet,
          builder: (_, __) => _stubPage('stub-wallet'),
        ),
        GoRoute(
          path: RouteNames.customerSupport,
          builder: (_, __) => _stubPage('stub-support'),
        ),
        GoRoute(
          path: RouteNames.ownerDashboard,
          builder: (_, __) => const OwnerDashboardView(shopId: 'shop-1'),
        ),
        GoRoute(
          path: RouteNames.ownerAddVehicle,
          builder: (_, __) => _stubPage('stub-add-vehicle'),
        ),
        GoRoute(
          path: RouteNames.ownerQrScan,
          builder: (_, __) => _stubPage('stub-qr-scan'),
        ),
        GoRoute(
          path: RouteNames.ownerManualBooking,
          builder: (_, __) => _stubPage('stub-manual-booking'),
        ),
        GoRoute(
          path: RouteNames.ownerFinance,
          builder: (_, __) => _stubPage('stub-finance'),
        ),
      ],
    );

/// E2: serves valid 1x1 PNG bytes for any image-asset load, so hero
/// tests can pump the car cards despite the repo's car PNGs being
/// corrupt placeholders (the known corrupt-PNG failures in the full
/// suite). Test-only; production assets are untouched. Non-PNG loads
/// delegate to the real bundle.
class _E2TestAssetBundle extends AssetBundle {
  static final Uint8List _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.png')) {
      return ByteData.view(_png.buffer);
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      rootBundle.loadString(key, cache: cache);

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) =>
      rootBundle.loadStructuredData(key, parser);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // CU-m3: the Home/Bookings screens load the signed-in user's own
  // data and show a signed-out error state otherwise. Widget tests
  // cannot sign a Firebase user in, so stand in as 'cust-101' via
  // the SignedInUser test override.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SignedInUser.override = const SignedInUserData(
      uid: 'cust-101',
      displayName: 'Ahmed Raza',
      phoneNumber: '03001234567',
    );
  });

  tearDown(() {
    SignedInUser.override = null;
  });

  group('QuickActionTiles widget', () {
    Future<void> pumpTiles(
      WidgetTester tester, {
      required List<QuickActionTile> tiles,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickActionTiles(tiles: tiles),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    List<QuickActionTile> testTiles(Map<String, bool> tapped) => [
          QuickActionTile(
            icon: Icons.directions_car_rounded,
            label: 'Book a Car',
            onTap: () => tapped['Book a Car'] = true,
          ),
          QuickActionTile(
            icon: Icons.qr_code_rounded,
            label: 'Scan Pass',
            onTap: () => tapped['Scan Pass'] = true,
          ),
          QuickActionTile(
            icon: Icons.storefront_rounded,
            label: 'Nearby Shops',
            onTap: () => tapped['Nearby Shops'] = true,
          ),
          QuickActionTile(
            icon: Icons.sos_rounded,
            label: 'SOS',
            onTap: () => tapped['SOS'] = true,
          ),
        ];

    testWidgets('renders all four labels with their icons', (tester) async {
      final tapped = <String, bool>{};
      await pumpTiles(tester, tiles: testTiles(tapped));
      for (final label in ['Book a Car', 'Scan Pass', 'Nearby Shops', 'SOS']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_rounded), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sos_rounded), findsOneWidget);
    });

    testWidgets('tapping each tile fires only its own callback',
        (tester) async {
      final tapped = <String, bool>{};
      await pumpTiles(tester, tiles: testTiles(tapped));
      for (final label in ['Book a Car', 'Scan Pass', 'Nearby Shops', 'SOS']) {
        await tester.tap(find.text(label));
        await tester.pump();
        expect(tapped[label], isTrue,
            reason: 'tapping $label should fire its onTap');
      }
      expect(tapped.length, 4);
    });

    testWidgets('every tile hit area is at least 48x48', (tester) async {
      final tapped = <String, bool>{};
      await pumpTiles(tester, tiles: testTiles(tapped));
      for (final label in ['Book a Car', 'Scan Pass', 'Nearby Shops', 'SOS']) {
        final size = tester.getSize(
          find.byKey(ValueKey('quick-action-$label')),
        );
        expect(size.width, greaterThanOrEqualTo(48),
            reason: '$label tile width ${size.width} < 48');
        expect(size.height, greaterThanOrEqualTo(48),
            reason: '$label tile height ${size.height} < 48');
      }
    });
  });

  group('MaskedValue widget', () {
    Future<void> pumpMasked(
      WidgetTester tester, {
      required String value,
      String? maskedValue,
      String showTooltip = 'Show balance',
      String hideTooltip = 'Hide balance',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MaskedValue(
              value: value,
              maskedValue: maskedValue,
              showTooltip: showTooltip,
              hideTooltip: hideTooltip,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('masked by default, reveals on eye tap, re-masks on '
        'second tap', (tester) async {
      await pumpMasked(tester, value: 'Rs. 125000');
      expect(find.text('Rs. ••••••'), findsOneWidget);
      expect(find.text('Rs. 125000'), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      expect(find.text('Rs. 125000'), findsOneWidget);
      expect(find.text('Rs. ••••••'), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_off_rounded));
      await tester.pump();
      expect(find.text('Rs. ••••••'), findsOneWidget);
      expect(find.text('Rs. 125000'), findsNothing);
    });

    testWidgets('eye toggle tooltips flip with the state', (tester) async {
      await pumpMasked(tester, value: 'Rs. 125000');
      expect(find.byTooltip('Show balance'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      expect(find.byTooltip('Hide balance'), findsOneWidget);
    });

    testWidgets('explicit maskedValue wins over the computed mask',
        (tester) async {
      await pumpMasked(
        tester,
        value: '35202-1234567-1',
        maskedValue: '35202-•••••••-1',
        showTooltip: 'Show CNIC',
        hideTooltip: 'Hide CNIC',
      );
      expect(find.text('35202-•••••••-1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      expect(find.text('35202-1234567-1'), findsOneWidget);
    });

    test('maskDigits masks every digit, maskCnic keeps the CNIC shape',
        () {
      expect(MaskedValue.maskDigits('Rs. 125000'), 'Rs. ••••••');
      expect(
        MaskedValue.maskCnic('35202-1234567-1'),
        '35202-•••••••-1',
      );
      expect(MaskedValue.maskCnic('3520212345671'), '•••••••••••••');
    });
  });

  group('ProfileCnicRow', () {
    testWidgets('shows the CNIC-shaped mask, reveals the real CNIC on tap',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileCnicRow(cnic: '35202-1234567-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('35202-•••••••-1'), findsOneWidget);
      expect(find.text('35202-1234567-1'), findsNothing);
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      expect(find.text('35202-1234567-1'), findsOneWidget);
    });
  });

  group('CustomerWalletView masking', () {
    testWidgets('balance and escrow pills are masked by default',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: CustomerWalletView()),
      );
      await tester.pumpAndSettle();
      // No backend in tests: totals are 0, so every amount renders as
      // the masked 'Rs. •' — the balance plus the two escrow pills.
      expect(find.text('Rs. •'), findsNWidgets(3));
      expect(find.text('Rs. 0'), findsNothing);
    });
  });

  group('DiscoveryCubit map toggle (Nearby Shops)', () {
    test('toggleMapView(true) switches the loaded home to the map view',
        () async {
      final cubit = DiscoveryCubit(
        getNearbyShopsUseCase:
            GetNearbyShopsUseCase(_FakeDiscoveryRepository()),
      );
      await cubit.fetchNearbyShops(radiusKm: 3.0);
      expect(cubit.state, isA<DiscoveryLoaded>());
      expect((cubit.state as DiscoveryLoaded).isMapView, isFalse);
      cubit.toggleMapView(true);
      expect(cubit.state, isA<DiscoveryLoaded>());
      expect((cubit.state as DiscoveryLoaded).isMapView, isTrue);
      await cubit.close();
    });
  });

  group('Customer Home tiles navigate', () {
    Future<void> pumpHome(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          routerConfig:
              _e1Router(initialLocation: RouteNames.customerHome),
        ),
      );
      await tester.pumpAndSettle();
      // Home redesign (2026-11-24): "Book a Car" is the action
      // row's FilledButton now (the recent-bookings empty state has
      // a second 'Book a Car' action, so the row's button is
      // asserted by its key).
      expect(find.byKey(const ValueKey('home-book-car')), findsOneWidget);
    }

    testWidgets('Book a Car opens the Shops tab', (tester) async {
      await pumpHome(tester);
      await tester.tap(find.byKey(const ValueKey('home-book-car')));
      await tester.pumpAndSettle();
      expect(find.text('stub-shops'), findsOneWidget);
    });

    testWidgets('Wallet opens the wallet', (tester) async {
      await pumpHome(tester);
      await tester
          .tap(find.byKey(const ValueKey('quick-action-Wallet')));
      await tester.pumpAndSettle();
      expect(find.text('stub-wallet'), findsOneWidget);
    });

    testWidgets('SOS opens the SOS screen', (tester) async {
      await pumpHome(tester);
      // The SOS chip sits below the fold in short viewports — scroll
      // it into view first, as a user would (the Home's scroll view
      // is the SingleChildScrollView ancestor of the SOS chip).
      await tester.drag(
        find.ancestor(
          of: find.byKey(const ValueKey('quick-action-SOS')),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();
      expect(find.text('stub-sos'), findsOneWidget);
    });

    testWidgets('Support opens the support inbox', (tester) async {
      await pumpHome(tester);
      await tester
          .tap(find.byKey(const ValueKey('quick-action-Support')));
      await tester.pumpAndSettle();
      expect(find.text('stub-support'), findsOneWidget);
    });

    testWidgets('Recent bookings View all opens the bookings list',
        (tester) async {
      await pumpHome(tester);
      await tester.ensureVisible(find.text('View all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();
      expect(find.text('stub-bookings'), findsOneWidget);
    });
  });

  group('Owner Dashboard tiles navigate', () {
    Future<void> pumpDashboard(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          routerConfig:
              _e1Router(initialLocation: RouteNames.ownerDashboard),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Car'), findsOneWidget);
    }

    testWidgets('Add Car opens the add-vehicle form', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.text('Add Car'));
      await tester.pumpAndSettle();
      expect(find.text('stub-add-vehicle'), findsOneWidget);
    });

    testWidgets('Scan QR opens the QR scanner', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.text('Scan QR'));
      await tester.pumpAndSettle();
      expect(find.text('stub-qr-scan'), findsOneWidget);
    });

    testWidgets('New Booking opens manual booking', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.text('New Booking'));
      await tester.pumpAndSettle();
      expect(find.text('stub-manual-booking'), findsOneWidget);
    });

    testWidgets('Finance opens the finance hub', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.text('Finance'));
      await tester.pumpAndSettle();
      expect(find.text('stub-finance'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------
  // E2 (Phase E, worker 2): shared feedback states, hero transitions,
  // haptics. The E1 groups above are untouched.
  //
  // Haptics mechanism: HapticFeedback.* sends a method call on
  // SystemChannels.platform ('HapticFeedback.vibrate' with an argument
  // like 'HapticFeedbackType.selectionClick'). The tests below install
  // a mock handler on that channel and record the calls — no device
  // vibrates, and the recorded (method, argument) pair proves which
  // feedback type each tap produced.
  // ------------------------------------------------------------------

  VehicleEntity e2Vehicle() => const VehicleEntity(
        vehicleId: 'v-1',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla',
        year: 2021,
        plateNumber: 'LEA-21-4820',
        rates: VehicleRatesEntity(daily24: 5000),
      );

  /// Wraps the app in the test asset bundle (see [_E2TestAssetBundle]).
  /// The bundle sits above [MaterialApp] so pushed routes see it too.
  Widget withTestAssets(Widget child) => DefaultAssetBundle(
        bundle: _E2TestAssetBundle(),
        child: child,
      );

  ShopEntity e2Shop() => const ShopEntity(
        shopId: 'shop-1',
        ownerId: 'owner-1',
        shopName: 'Al-Madina Rent a Car',
        phoneNumber: '03001234567',
        address: 'Main Boulevard',
        city: 'Lahore',
        geoLocation: GeoPointEntity(31.52, 74.35),
      );

  BookingEntity e2Booking() => BookingEntity(
        bookingId: 'RH-1762574400123-0042',
        customerId: 'cust-101',
        shopId: 'shop-1',
        vehicleId: 'v-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 8, 10),
        returnTime: DateTime(2026, 11, 9, 10),
        totalAmount: 1250000,
        remainingBalance: 1250000,
        status: 'requested',
        vehicleName: 'Toyota Corolla Grande 1.8',
        vehiclePlate: 'LEA-21-4820',
        shopName: 'Al-Madina Rent a Car',
        customerName: 'Muhammad Ahmed Khan Butt',
        customerPhone: '0300-1234567',
      );

  Future<List<MethodCall>> recordHaptics(
    WidgetTester tester,
    Future<void> Function() act,
  ) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await act();
    await tester.pump();
    await tester.pump();
    return calls;
  }

  bool hasHaptic(List<MethodCall> calls, String type) => calls.any(
        (c) =>
            c.method == 'HapticFeedback.vibrate' &&
            c.arguments == 'HapticFeedbackType.$type',
      );

  group('AppStateViews widgets', () {
    Future<void> pumpState(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
      );
      // One frame only: pumpAndSettle never returns while a
      // CircularProgressIndicator is animating.
      await tester.pump();
    }

    testWidgets('AppLoadingState shows a spinner and its message',
        (tester) async {
      await pumpState(
        tester,
        const AppLoadingState(message: 'Loading your reservations…'),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your reservations…'), findsOneWidget);
    });

    testWidgets('AppEmptyState shows title/message and fires its action',
        (tester) async {
      var fired = false;
      await pumpState(
        tester,
        AppEmptyState(
          title: 'No customers yet',
          message: 'Scan a CNIC or take a walk-in booking.',
          actionLabel: 'Scan a CNIC',
          onAction: () => fired = true,
        ),
      );
      expect(find.text('No customers yet'), findsOneWidget);
      expect(
        find.text('Scan a CNIC or take a walk-in booking.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Scan a CNIC'));
      await tester.pump();
      expect(fired, isTrue);
    });

    testWidgets('AppEmptyState without an action renders no button',
        (tester) async {
      await pumpState(
        tester,
        const AppEmptyState(title: 'No bookings found.'),
      );
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('AppErrorState shows its message and fires retry',
        (tester) async {
      var retried = false;
      await pumpState(
        tester,
        AppErrorState(
          message: 'Could not load your bookings.',
          onRetry: () => retried = true,
        ),
      );
      expect(find.textContaining('Could not load your bookings.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('AppErrorState without retry renders no button',
        (tester) async {
      await pumpState(
        tester,
        const AppErrorState(message: 'Something went wrong.'),
      );
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('Vehicle hero transition', () {
    test('vehicleHeroTag is stable and per-vehicle', () {
      expect(vehicleHeroTag('v-1'), 'vehicle-image-v-1');
      expect(vehicleHeroTag('v-2'), 'vehicle-image-v-2');
      expect(vehicleHeroTag('v-1'), isNot(vehicleHeroTag('v-2')));
    });

    testWidgets('both cards carry a Hero with the same tag', (tester) async {
      final vehicle = e2Vehicle();
      await tester.pumpWidget(
        withTestAssets(
          MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ShopVehicleCard(vehicle: vehicle))),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is Hero && w.tag == vehicleHeroTag('v-1'),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        withTestAssets(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: VehicleHeroCard(
                vehicle: vehicle,
                carAsset: 'assets/images/white_sedan_hero.png',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is Hero && w.tag == vehicleHeroTag('v-1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping a shop card navigates to a detail holding the '
        'same hero', (tester) async {
      final vehicle = e2Vehicle();
      await tester.pumpWidget(
        withTestAssets(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: ShopVehicleCard(
                  vehicle: vehicle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: SingleChildScrollView(
                          child: VehicleHeroCard(
                            vehicle: vehicle,
                            carAsset:
                                'assets/images/white_sedan_hero.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VehicleHeroCard), findsNothing);

      await tester.tap(find.text('Toyota Corolla 2021'));
      await tester.pumpAndSettle();

      // Navigation happened: the detail's hero card is on screen…
      expect(find.byType(VehicleHeroCard), findsOneWidget);
      // …and the tag exists on both sides of the transition (the
      // source route stays in the tree, offstage, during the flight —
      // hence skipOffstage: false).
      expect(
        find.byWidgetPredicate(
          (w) => w is Hero && w.tag == vehicleHeroTag('v-1'),
          skipOffstage: false,
        ),
        findsNWidgets(2),
      );
    });
  });

  group('Haptics', () {
    testWidgets('tab tap fires a selectionClick', (tester) async {
      var tapped = -1;
      final calls = await recordHaptics(tester, () async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AppShellNav(
                currentIndex: 0,
                onTap: (i) => tapped = i,
                items: const [
                  ShellNavItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  ShellNavItem(
                    icon: Icon(Icons.book_rounded),
                    label: 'Bookings',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bookings'));
      });
      expect(tapped, 1);
      expect(hasHaptic(calls, 'selectionClick'), isTrue);
      expect(hasHaptic(calls, 'lightImpact'), isFalse);
    });

    testWidgets('primary CTA tap fires a lightImpact', (tester) async {
      var pressed = false;
      final calls = await recordHaptics(tester, () async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DebouncedButton(
                text: 'Send Request',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Send Request'));
      });
      expect(pressed, isTrue);
      expect(hasHaptic(calls, 'lightImpact'), isTrue);
      expect(hasHaptic(calls, 'selectionClick'), isFalse);
    });
  });

  group('WalletLedger states', () {
    Future<void> pumpLedger(
      WidgetTester tester, {
      required bool isLoading,
      required List<WalletLedgerEntry> entries,
      bool hasError = false,
      VoidCallback? onRetry,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WalletLedger(
              isLoading: isLoading,
              entries: entries,
              hasError: hasError,
              onRetry: onRetry,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('loading renders the shared loading state', (tester) async {
      await pumpLedger(tester, isLoading: true, entries: const []);
      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('error renders the shared error state and retry fires',
        (tester) async {
      var retried = false;
      await pumpLedger(
        tester,
        isLoading: false,
        entries: const [],
        hasError: true,
        onRetry: () => retried = true,
      );
      expect(find.byType(AppErrorState), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('empty renders the shared empty state', (tester) async {
      await pumpLedger(tester, isLoading: false, entries: const []);
      expect(find.text('No wallet activity yet.'), findsOneWidget);
      expect(find.byType(AppEmptyState), findsOneWidget);
    });
  });

  group('FleetBody states', () {
    Future<void> pumpBody(WidgetTester tester, FleetState state,
        {List<VehicleEntity> fleet = const [],
        List<VehicleEntity> filtered = const [],
        VoidCallback? onAddVehicle,
        VoidCallback? onRetry}) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FleetBody(
                state: state,
                fleet: fleet,
                filtered: filtered,
                onAddVehicle: onAddVehicle ?? () {},
                onRetry: onRetry ?? () {},
                onEditRates: (_) {},
                onOutCityRules: (_) {},
                onTapVehicle: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('loading renders the shared loading state', (tester) async {
      await pumpBody(tester, const FleetLoading());
      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('error shows the message and retry fires', (tester) async {
      var retried = false;
      await pumpBody(
        tester,
        const FleetError('boom'),
        onRetry: () => retried = true,
      );
      expect(find.textContaining('Could not load your fleet: boom'),
          findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('empty fleet shows the add-vehicle action', (tester) async {
      var added = false;
      await pumpBody(
        tester,
        const FleetLoaded(vehicles: [], tier: 'basic'),
        onAddVehicle: () => added = true,
      );
      expect(find.text('No vehicles yet — add your first car'),
          findsOneWidget);
      await tester.tap(find.text('Add Vehicle Now'));
      await tester.pump();
      expect(added, isTrue);
    });

    testWidgets('a filter with no matches shows no add action',
        (tester) async {
      final vehicle = e2Vehicle();
      await pumpBody(
        tester,
        FleetLoaded(vehicles: [vehicle], tier: 'basic'),
        fleet: [vehicle],
        filtered: const [],
      );
      expect(find.text('No vehicles found in this filter'), findsOneWidget);
      expect(find.text('Add Vehicle Now'), findsNothing);
    });
  });

  group('SupportFaqList states', () {
    testWidgets('no matches renders the shared empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SupportFaqList(faqs: [])),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No help topics match your search.'), findsOneWidget);
    });

    testWidgets('faqs render their questions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SupportFaqList(faqs: const [
              {'q': 'When is my deposit returned?', 'a': 'At return.'},
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('When is my deposit returned?'), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
    });
  });

  group('E2 tab screens: shared loading / empty / error states', () {
    // Mirrors test/ui_seeded_overflow_test.dart: real DI, no Firebase
    // backend, so the data sources fall back to their empty in-memory
    // lists and the screens settle to their empty states. Error states
    // are forced per test by unregistering the data source the screen
    // loads through — the load then throws inside its try/catch and the
    // screen renders AppErrorState with retry.
    setUp(() async {
      await sl.reset();
      SharedPreferences.setMockInitialValues({});
      await initDependencies();
    });

    tearDown(() async {
      await sl.reset();
    });

    Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
      await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: screen));
    }

    testWidgets('customer Home: loading state, then the dashboard '
        'empty states', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
          routerConfig:
              _e1Router(initialLocation: RouteNames.customerHome),
        ),
      );
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingState), findsNothing);
      // The reworked Home is a dashboard (KPIs, KYC, quick actions,
      // recent + upcoming) with honest empty states — the discovery
      // radar and its EmptyRadarState moved to the Shops tab.
      expect(find.byType(EmptyRadarState), findsNothing);
      expect(find.text('No bookings yet'), findsOneWidget);
      // Home redesign (2026-11-24): with nothing coming up the
      // Upcoming section hides entirely — no empty-state box.
      expect(find.text('Nothing coming up'), findsNothing);
    });

    testWidgets('customer Bookings: loading, then shared empty state',
        (tester) async {
      await pumpScreen(tester, const CustomerBookingsView());
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No All bookings found.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('customer Bookings: missing data source renders the '
        'shared error state with retry', (tester) async {
      await sl.unregister<BookingRemoteDataSource>();
      await pumpScreen(tester, const CustomerBookingsView());
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.textContaining('Could not load your bookings.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
    });

    testWidgets('customer Wallet: loading, then shared empty ledger',
        (tester) async {
      await pumpScreen(tester, const CustomerWalletView());
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('No wallet activity yet.'), findsOneWidget);
    });

    testWidgets('customer Wallet: missing data source renders the shared '
        'error state', (tester) async {
      await sl.unregister<BookingRemoteDataSource>();
      await pumpScreen(tester, const CustomerWalletView());
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.textContaining('Could not load your wallet.'), findsOneWidget);
    });

    testWidgets('customer Support: a search with no matches renders the '
        'shared empty state', (tester) async {
      await pumpScreen(tester, const CustomerSupportView());
      await tester.pumpAndSettle();
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Search help'),
        'zzzznope',
      );
      await tester.pump();
      expect(find.text('No help topics match your search.'), findsOneWidget);
    });

    testWidgets('customer Profile: settles to the real profile content',
        (tester) async {
      await pumpScreen(tester, const CustomerProfileView());
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingState), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Guest renders once in the hero header (not duplicated in the
      // identity card).
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('owner Dashboard: loading, then honest empty ledger',
        (tester) async {
      await pumpScreen(tester, const OwnerDashboardView(shopId: 'shop-1'));
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingState), findsNothing);
      expect(
        find.text('No trips yet — bookings will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('owner Dashboard: missing data source renders the shared '
        'error state with retry', (tester) async {
      await sl.unregister<BookingRemoteDataSource>();
      await pumpScreen(tester, const OwnerDashboardView(shopId: 'shop-1'));
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.textContaining('Could not load your dashboard.'), findsOneWidget);
    });

    testWidgets('owner Fleet: loading, then shared empty state with add '
        'action', (tester) async {
      await pumpScreen(tester, const OwnerFleetView());
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('No vehicles yet — add your first car'),
          findsOneWidget);
      expect(find.text('Add Vehicle Now'), findsOneWidget);
    });

    testWidgets('owner Requests: loading, then shared empty state',
        (tester) async {
      await pumpScreen(tester, const OwnerBookingRequestsView(shopId: 'shop-1'));
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(AppEmptyState), findsOneWidget);
      // FG-4: the default triage filter is now proofs-first, so the
      // empty state shows the proof queue text, not the New text.
      expect(find.text('No payment proofs waiting for verification'), findsOneWidget);
    });

    testWidgets('owner Requests: missing data source renders the shared '
        'error state', (tester) async {
      await sl.unregister<BookingRemoteDataSource>();
      await pumpScreen(tester, const OwnerBookingRequestsView(shopId: 'shop-1'));
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(
        find.textContaining('Could not load booking requests.'),
        findsOneWidget,
      );
    });

    testWidgets('owner Customers: loading, then shared empty state',
        (tester) async {
      await pumpScreen(tester, const OwnerCustomersListView());
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('No customers yet'), findsOneWidget);
      expect(find.byType(AppEmptyState), findsOneWidget);
    });

    testWidgets('owner Customers: missing data source renders the shared '
        'error state', (tester) async {
      await sl.unregister<BookingRemoteDataSource>();
      await pumpScreen(tester, const OwnerCustomersListView());
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.textContaining('Could not load your customers.'), findsOneWidget);
    });

    testWidgets('owner Settings: no loading/empty/error state exists to '
        'migrate', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: OwnerSettingsView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingState), findsNothing);
      expect(find.byType(AppEmptyState), findsNothing);
      expect(find.byType(AppErrorState), findsNothing);
    });

    testWidgets('shop detail: loading, then shared empty state',
        (tester) async {
      await pumpScreen(tester, ShopDetailView(shop: e2Shop()));
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('This shop has no cars listed yet.'), findsOneWidget);
    });

    testWidgets('shop detail: missing data source renders the shared '
        'error state', (tester) async {
      await sl.unregister<FleetRemoteDataSource>();
      await pumpScreen(tester, ShopDetailView(shop: e2Shop()));
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(
        find.textContaining('Could not load this showroom’s cars.'),
        findsOneWidget,
      );
    });

    testWidgets('shop cars: loading, then shared empty state',
        (tester) async {
      await pumpScreen(
        tester,
        const ShopCarsView(shopId: 'shop-1', shopName: 'Al-Madina'),
      );
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(
        find.text('No All vehicles available right now.'),
        findsOneWidget,
      );
    });

    testWidgets('shop cars: missing data source renders the shared error '
        'state', (tester) async {
      await sl.unregister<FleetRemoteDataSource>();
      await pumpScreen(
        tester,
        const ShopCarsView(shopId: 'shop-1', shopName: 'Al-Madina'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(
        find.textContaining('Could not load this showroom’s cars.'),
        findsOneWidget,
      );
    });

    testWidgets('payment accounts: loading, then shared empty state',
        (tester) async {
      // §10: a merely `requested` booking renders the decision
      // detail, not the accounts — the accounts path needs an
      // approved booking.
      await pumpScreen(
        tester,
        OwnerPaymentAccountsView(
            booking: e2Booking().copyWith(status: 'approved')),
      );
      expect(find.byType(AppLoadingState), findsOneWidget);
      await tester.pumpAndSettle();
      expect(
        find.text('No payment accounts configured for this shop yet.'),
        findsOneWidget,
      );
    });
  });
}
