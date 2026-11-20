import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_filter_chips.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_quick_actions.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_search_field.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Phone-test round 4 (Worker 4): the fleet tab's actions —
// Add Vehicle navigating to its real sub-screen, plus the
// `onEditDetails` wiring (Worker 3 owns the card/body side).
//
// User layout 2026-11-18: the header holds the orange "+ Add
// Vehicle" pill (the FAB overlapped the third card on a phone);
// the white search bar is back under the header as a search-only
// bar. Item 1 (2026-11-20): the Schedule and Handover QR buttons
// that used to live inside the search bar are REMOVED as
// duplicates — the calendar stays reachable from the Bookings
// app bar, the QR scan from Dashboard / Bookings /
// booking-confirmed — so the navigation tests for them are gone
// and absence is asserted instead. Customers left the fleet
// screen — it stays reachable from the Customers tab, so there is
// no Customers button here any more.
//
// The local copy's PNG assets are corrupt (downloaded through the
// connector's text path), so any widget rendering a car photo throws
// "Invalid image data" locally while passing in CI. This bundle answers
// every image load with a valid 1x1 PNG (same trick as
// owner_phase_b_fleet_test).
class _TestAssetBundle extends AssetBundle {
  static final ByteData _pixel = ByteData.view(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ).buffer);

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec()
          .encodeMessage(<String, Object>{})!;
    }
    return _pixel;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '{}';
}

Widget _stub(String label) =>
    Scaffold(body: Center(child: Text(label)));

/// Test router mirroring the real branch structure (app_router.dart):
/// the Fleet branch holds the fleet tab and its same-branch screens
/// (add, calendar, edit-details); Requests holds the requests list and
/// the QR scan; Customers holds the customers list. Cross-branch
/// destinations are reached with `go` (tab-switch semantic); the
/// same-branch ones with `push`.
///
/// Note: a `push` inside a shell branch renders the pushed page but
/// does NOT move `routeInformationProvider.value.uri` (it stays at the
/// branch location), so push destinations are asserted on the rendered
/// stub page, not the URI — the same way ui_back_navigation_test
/// asserts pushed screens.
GoRouter _buildRouter({String shopId = 'shop-basic'}) {
  return GoRouter(
    initialLocation: RouteNames.ownerFleet,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => shell,
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.ownerFleet,
              builder: (context, state) => OwnerFleetView(shopId: shopId),
            ),
            GoRoute(
              path: RouteNames.ownerAddVehicle,
              builder: (context, state) => _stub('Add vehicle stub'),
            ),
            GoRoute(
              path: RouteNames.ownerFleetCalendar,
              builder: (context, state) => _stub('Calendar stub'),
            ),
            GoRoute(
              path: RouteNames.ownerEditVehicle,
              builder: (context, state) => _stub('Edit vehicle stub'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.ownerRequests,
              builder: (context, state) => _stub('Requests stub'),
            ),
            GoRoute(
              path: RouteNames.ownerQrScan,
              builder: (context, state) => _stub('Scan stub'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.ownerCustomers,
              builder: (context, state) => _stub('Customers stub'),
            ),
          ]),
        ],
      ),
    ],
  );
}

Future<void> _pumpFleet(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _TestAssetBundle(),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The AppBar actions and the FAB are always visible at the test
/// width — tap directly after ensuring visibility.
Future<void> _tapAction(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Fleet tab actions (header pill, search bar, filter bar)', () {
    testWidgets('segmented bar exists; search bar is back under the header',
        (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      expect(find.byType(FleetFilterChips), findsOneWidget);
      expect(find.byType(FleetQuickActions), findsNothing);
      expect(find.text('All (3)'), findsOneWidget);
      // User layout 2026-11-18: the search bar is back as a
      // search-only bar (Item 1, 2026-11-20: Schedule + Handover QR
      // removed as duplicates) and Add Vehicle is the orange
      // header pill, not a FAB.
      expect(find.byType(FleetSearchField), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('fleet-action-add-vehicle')), findsOneWidget);
      expect(find.text('Add Vehicle'), findsOneWidget);
    });

    testWidgets('header pill fits at 360px without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await _pumpFleet(tester, router);

      expect(find.text('Fleet Management'), findsOneWidget);
      expect(find.byKey(const Key('fleet-action-add-vehicle')), findsOneWidget);
      // Item 1 (2026-11-20): Schedule + Handover QR are gone from
      // the search bar (duplicates) — the header shows title + pill
      // only and the bar is search-only.
      expect(find.byKey(const Key('fleet-action-schedule')), findsNothing);
      expect(find.byKey(const Key('fleet-action-handover')), findsNothing);
      expect(find.byType(FleetSearchField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search bar has no action buttons; search still filters by name/plate',
        (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      // The magnifier prefix (search affordance) stays; the two
      // duplicate action buttons and their tooltips are gone.
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byKey(const Key('fleet-action-schedule')), findsNothing);
      expect(find.byKey(const Key('fleet-action-handover')), findsNothing);
      expect(find.byTooltip('Schedule'), findsNothing);
      expect(find.byTooltip('Handover QR'), findsNothing);

      // Search still filters: 'Civic' leaves only the Civic card.
      await tester.enterText(find.byType(TextField), 'Civic');
      await tester.pumpAndSettle();
      expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
      expect(find.text('Toyota Corolla Grande 2022'), findsNothing);
      expect(find.text('Suzuki Alto VXL 2023'), findsNothing);

      // Clearing the query restores all three cards.
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
      expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
      expect(find.text('Suzuki Alto VXL 2023'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every action exists with its icon + label or tooltip',
        (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      // Item 1 (2026-11-20): the only fleet action left is Add
      // Vehicle, the header pill (icon + text label). Schedule and
      // Handover QR were removed from the search bar as duplicates
      // (calendar via Bookings app bar, scan via Dashboard /
      // Bookings) — assert they are absent, not present.
      // Customers left the fleet screen (still on the Customers
      // tab) — no button here.
      expect(find.byKey(const Key('fleet-action-schedule')), findsNothing);
      expect(find.byKey(const Key('fleet-action-handover')), findsNothing);
      expect(find.byTooltip('Schedule'), findsNothing);
      expect(find.byTooltip('Handover QR'), findsNothing);
      final button = find.byKey(const Key('fleet-action-add-vehicle'));
      expect(button, findsOneWidget, reason: 'missing action: Add Vehicle');
      expect(
        find.descendant(of: button, matching: find.byIcon(Icons.add_rounded)),
        findsOneWidget,
        reason: 'missing icon for: Add Vehicle',
      );
      expect(
        find.descendant(of: button, matching: find.text('Add Vehicle')),
        findsOneWidget,
        reason: 'missing label for: Add Vehicle',
      );
      expect(find.byKey(const Key('fleet-action-customers')), findsNothing);
    });

    testWidgets('Add Vehicle navigates to the add-vehicle flow',
        (tester) async {
      // shop-empty: the free plan's 3-car cap would otherwise show the
      // limit sheet instead of navigating (shop-basic already has 3).
      final router = _buildRouter(shopId: 'shop-empty');
      await _pumpFleet(tester, router);

      await _tapAction(tester, 'fleet-action-add-vehicle');

      expect(find.text('Add vehicle stub'), findsOneWidget);
    });

    testWidgets('card Edit icon pushes the edit-details route',
        (tester) async {
      // Compact width (< 600dp) so the fleet renders through FleetBody
      // (the `onEditDetails` wiring) rather than the two-column grid.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await _pumpFleet(tester, router);

      // The card's Edit control (Worker 3): an icon + short 'Edit'
      // label in the action row under the photo. The first card is
      // the first seeded vehicle.
      final edit = find.text('Edit').first;
      await tester.ensureVisible(edit);
      await tester.pumpAndSettle();
      await tester.tap(edit);
      await tester.pumpAndSettle();

      expect(find.text('Edit vehicle stub'), findsOneWidget);
    });
  });
}
