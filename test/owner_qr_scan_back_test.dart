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

// QR scan back button (Item 1): the Fleet search bar reaches the scan
// screen with `go()` (owner_fleet_view.dart), and /owner/scan lives in
// the Bookings StatefulShellBranch, so go() makes it that branch's
// root — canPop is false, a plain context.pop() is a no-op, and the
// user was stranded (no bottom nav on /owner/scan either). The view
// now falls back to go(RouteNames.ownerFleet) when it cannot pop.
// These tests pin that: back from the Fleet path lands on /owner/fleet.
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
/// requests list and the QR scan. The Fleet Handover button crosses
/// branches with `go`, exactly like the real fleet view does.
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

    testWidgets('back from the Fleet-reached scan lands on /owner/fleet',
        (tester) async {
      await _pumpRouter(tester, router);
      expect(find.byType(OwnerFleetView), findsOneWidget);

      // The real Fleet Handover button: go() to the scan screen.
      final handover = find.byKey(const Key('fleet-action-handover'));
      await tester.ensureVisible(handover);
      await tester.pumpAndSettle();
      await tester.tap(handover);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          RouteNames.ownerQrScan);
      expect(find.byType(OwnerQrScanView), findsOneWidget);
      // go() made the scan the Bookings branch root: nothing to pop.
      expect(router.canPop(), isFalse);

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
