import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_qr_scan_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// QR scan back button (Item 1): /owner/scan lives in the
// Bookings StatefulShellBranch. The scan view falls back to
// go(RouteNames.ownerFleet) when it cannot pop, so back from a
// pushed scan lands on /owner/fleet. These tests pin that.
//
// Item 1 (2026-11-20): the Fleet search bar's Handover button —
// which used to reach the scan with `go()` (making it that
// branch's root, canPop false) — is REMOVED as a duplicate. The
// scan stays reachable via push() from the Dashboard quick action,
// the Bookings app-bar QR icon, and booking-confirmed, so the
// back behaviour is now pinned through the push() path only; the
// first test also asserts the fleet Handover entry is gone.
//
// The local copy's PNG assets are corrupt (downloaded through the
// connector's text path), so any widget rendering a car photo throws
// "Invalid image data" locally while passing in CI. This bundle answers
// every image load with a valid 1x1 PNG (same trick as
// owner_phase_b_fleet_test / fleet_tab_actions_test).
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

/// Test router mirroring the real branch structure (app_router.dart):
/// Fleet branch holds the fleet tab; the Bookings branch holds the
/// requests list and the QR scan. The scan is reached with push()
/// (Dashboard / Bookings path), exactly like the real app does now
/// that the Fleet Handover go() entry is removed (Item 1).
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: RouteNames.ownerFleet,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => shell,
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.ownerFleet,
              builder: (context, state) =>
                  const OwnerFleetView(shopId: 'shop-basic'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.ownerRequests,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Requests stub'))),
            ),
            GoRoute(
              path: RouteNames.ownerQrScan,
              builder: (context, state) => const OwnerQrScanView(),
            ),
          ]),
        ],
      ),
    ],
  );
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('QR scan back button (Fleet go() path)', () {
    late GoRouter router;

    setUp(() => router = _buildRouter());
    tearDown(() => router.dispose());

    testWidgets('fleet Handover entry is gone; back pops from a pushed scan to /owner/fleet',
        (tester) async {
      await _pumpRouter(tester, router);
      expect(find.byType(OwnerFleetView), findsOneWidget);

      // Item 1 (2026-11-20): no Handover (or Schedule) button in
      // the fleet search bar any more — the scan is reached from
      // Dashboard / Bookings instead.
      expect(find.byKey(const Key('fleet-action-handover')), findsNothing);
      expect(find.byKey(const Key('fleet-action-schedule')), findsNothing);

      // Dashboard / Bookings reach the scan with push(), so a real
      // stack entry exists and back must pop it. (A push inside a
      // shell branch renders the pushed page but does NOT move the
      // URI, so the destination is asserted on the rendered view,
      // not the URI.)
      router.push(RouteNames.ownerQrScan);
      await tester.pumpAndSettle();

      expect(find.byType(OwnerQrScanView), findsOneWidget);
      expect(router.canPop(), isTrue);

      // The back arrow in the scan screen's MinimalAppBar.
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          RouteNames.ownerFleet);
      expect(find.byType(OwnerFleetView), findsOneWidget);
      expect(find.byType(OwnerQrScanView), findsNothing);
    });

    testWidgets('back still pops when the scan was pushed (Dashboard path)',
        (tester) async {
      await _pumpRouter(tester, router);
      expect(find.byType(OwnerFleetView), findsOneWidget);

      // Dashboard quick action / Bookings QR icon reach the scan with
      // push(), so a real stack entry exists and back must pop it.
      router.push(RouteNames.ownerQrScan);
      await tester.pumpAndSettle();
      expect(find.byType(OwnerQrScanView), findsOneWidget);
      expect(router.canPop(), isTrue);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(OwnerFleetView), findsOneWidget);
      expect(find.byType(OwnerQrScanView), findsNothing);
    });
  });
}
