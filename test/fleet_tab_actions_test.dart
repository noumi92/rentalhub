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
import 'package:rentalhub/l10n/app_localizations.dart';

// Phone-test round 4 (Worker 4): the fleet tab's quick-action row
// beneath the KPI tiles — Handover, Requests, Add Vehicle, Schedule,
// Customers — each navigating to its real sub-screen, plus the
// `onEditDetails` wiring (Worker 3 owns the card/body side).
//
// Showroom redesign (Phase 2, 2026-11-16): the actions moved —
// Handover QR + Requests live inside the search bar (icon-only,
// tooltip-labelled), Add Vehicle is the orange pill in the AppBar,
// and the quick-actions row keeps only Schedule + Customers. The KPI
// tiles are gone, merged into the segmented filter bar
// ([FleetFilterChips]: All / Ready / On Rent / Maintenance). The
// destinations are unchanged, so the navigation tests below still
// address the same keys.
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

/// The row scrolls horizontally, so a later button can sit off-screen
/// at the 800px test width — scroll it into view before tapping.
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

  group('Fleet tab actions (search bar, segmented bar, quick actions)', () {
    testWidgets('segmented bar exists and the action row sits beneath it',
        (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      expect(find.byType(FleetFilterChips), findsOneWidget);
      expect(find.byType(FleetQuickActions), findsOneWidget);
      expect(find.text('All (3)'), findsOneWidget);
      final barBottom =
          tester.getBottomLeft(find.byType(FleetFilterChips)).dy;
      final actionsTop =
          tester.getTopLeft(find.byType(FleetQuickActions)).dy;
      expect(actionsTop, greaterThanOrEqualTo(barBottom));
    });

    testWidgets('every action exists with its icon + label or tooltip',
        (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      // Search-bar actions are icon-only (tooltip carries the label);
      // the AppBar pill and the quick-actions row keep text labels.
      final actions = <(String key, IconData icon, String label, bool isTooltip)>[
        ('fleet-action-handover', Icons.qr_code_scanner_rounded, 'Handover QR', true),
        ('fleet-action-requests', Icons.inbox_rounded, 'Requests', true),
        ('fleet-action-add-vehicle', Icons.add_rounded, 'Add Vehicle', false),
        ('fleet-action-schedule', Icons.calendar_month_rounded, 'Schedule', false),
        ('fleet-action-customers', Icons.people_outline_rounded, 'Customers', false),
      ];
      for (final (key, icon, label, isTooltip) in actions) {
        final button = find.byKey(Key(key));
        expect(button, findsOneWidget, reason: 'missing action: $label');
        expect(
          find.descendant(of: button, matching: find.byIcon(icon)),
          findsOneWidget,
          reason: 'missing icon for: $label',
        );
        if (isTooltip) {
          expect(find.byTooltip(label), findsOneWidget,
              reason: 'missing tooltip for: $label');
        } else {
          expect(
            find.descendant(of: button, matching: find.text(label)),
            findsOneWidget,
            reason: 'missing label for: $label',
          );
        }
      }
    });

    testWidgets('Handover navigates to the QR scan screen',
        (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      await _tapAction(tester, 'fleet-action-handover');

      expect(router.routeInformationProvider.value.uri.path,
          RouteNames.ownerQrScan);
      expect(find.text('Scan stub'), findsOneWidget);
    });

    testWidgets('Requests navigates to the requests list', (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      await _tapAction(tester, 'fleet-action-requests');

      expect(router.routeInformationProvider.value.uri.path,
          RouteNames.ownerRequests);
      expect(find.text('Requests stub'), findsOneWidget);
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

    testWidgets('Schedule navigates to the fleet calendar', (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      await _tapAction(tester, 'fleet-action-schedule');

      expect(find.text('Calendar stub'), findsOneWidget);
    });

    testWidgets('Customers navigates to the customers list', (tester) async {
      final router = _buildRouter();
      await _pumpFleet(tester, router);

      await _tapAction(tester, 'fleet-action-customers');

      expect(router.routeInformationProvider.value.uri.path,
          RouteNames.ownerCustomers);
      expect(find.text('Customers stub'), findsOneWidget);
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
