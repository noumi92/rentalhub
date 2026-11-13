import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/platform/app_platform.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/routing/auth_route_guard.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';

/// The web build is the admin panel (mobile is customer + owner).
/// Reported 2026-11-10: opening the admin panel showed the mobile
/// customer/owner login (/auth, Google sign-in) because the single
/// router sent every signed-out visitor there and nothing pointed at
/// /admin/login. These tests pin the fix: on web, every non-/admin
/// location and the post-splash destination resolve to the admin login
/// (or the admin dashboard for a signed-in user), and the mobile
/// behaviour is unchanged.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthRemoteDataSource authDataSource;

  setUp(() async {
    await sl.reset();
    // Audit SH-C1: saveProfileInfo fails closed with no signed-in user
    // and no cached uid. The signed-in tests simulate a signed-in user
    // through the cached-uid path the data source explicitly supports.
    SharedPreferences.setMockInitialValues(
        {'rentalhub_user_uid': 'usr_pk_001'});
    prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => prefs);

    authDataSource = AuthRemoteDataSource(prefs: prefs);
    sl.registerLazySingleton<AuthRemoteDataSource>(() => authDataSource);
    AppPlatform.isWebOverride = true;
  });

  tearDown(() async {
    AppPlatform.resetOverrides();
    await sl.reset();
  });

  GoRouterState createMockState(String location) {
    return GoRouterState(
      AppRouter.router.configuration,
      uri: Uri.parse(location),
      matchedLocation: location,
      fullPath: location,
      pathParameters: const {},
      pageKey: ValueKey(location),
    );
  }

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    return tester.element(find.byType(SizedBox));
  }

  group('Web, signed out: the admin login is the only entry point', () {
    test('post-splash destination is the admin login, not the mobile login',
        () {
      expect(authDataSource.isLoggedIn, isFalse);
      expect(
        AuthRouteGuard.resolveAuthDestination(),
        RouteNames.adminLogin,
      );
    });

    testWidgets('every mobile route redirects to the admin login',
        (tester) async {
      final context = await pumpContext(tester);
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.auth)),
        RouteNames.adminLogin,
      );
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.customerHome)),
        RouteNames.adminLogin,
      );
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.ownerFleet)),
        RouteNames.adminLogin,
      );
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.onboardingProfile)),
        RouteNames.adminLogin,
      );
    });

    testWidgets('splash and the admin login itself stay reachable',
        (tester) async {
      final context = await pumpContext(tester);
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.splash)),
        isNull,
      );
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.adminLogin)),
        isNull,
      );
    });
  });

  group('Web, signed in: the admin dashboard is the destination', () {
    test('post-splash destination is the admin dashboard', () async {
      await authDataSource.setLoggedIn(true);
      await authDataSource.saveProfileInfo(
          fullName: 'Admin User', phone: '03001234567');
      await authDataSource.assignPermanentRole(
          role: 'customer',
          fullName: 'Admin User',
          phone: '03001234567');
      await authDataSource.setOnboardingCompleted(true);

      expect(
        AuthRouteGuard.resolveAuthDestination(),
        RouteNames.adminDashboard,
      );
    });

    testWidgets(
        'a signed-in user without a Firebase session cannot open mobile routes on web',
        (tester) async {
      await authDataSource.setLoggedIn(true);
      await authDataSource.setOnboardingCompleted(true);
      final context = await pumpContext(tester);
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.auth)),
        RouteNames.adminLogin,
      );
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.customerHome)),
        RouteNames.adminLogin,
      );
    });

    testWidgets(
        'a signed-in user without a Firebase session cannot open /admin either',
        (tester) async {
      await authDataSource.setLoggedIn(true);
      await authDataSource.setOnboardingCompleted(true);
      final context = await pumpContext(tester);
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.adminDashboard)),
        RouteNames.adminLogin,
      );
    });
  });

  group('Web starts on the admin login, with no splash', () {
    test('initial location is the admin login on web, not the splash', () {
      expect(AppRouter.initialLocation, RouteNames.adminLogin);
      expect(AppRouter.initialLocation, isNot(RouteNames.splash));
    });

    test('a signed-in admin still reaches the dashboard', () async {
      await authDataSource.setLoggedIn(true);
      await authDataSource.saveProfileInfo(
          fullName: 'Admin User', phone: '03001234567');
      await authDataSource.assignPermanentRole(
          role: 'customer',
          fullName: 'Admin User',
          phone: '03001234567');
      await authDataSource.setOnboardingCompleted(true);

      // The web entry point stays the login route; the login view
      // auto-continues a signed-in admin, and the guard resolves the
      // dashboard as the post-auth destination.
      expect(AppRouter.initialLocation, RouteNames.adminLogin);
      expect(
        AuthRouteGuard.resolveAuthDestination(),
        RouteNames.adminDashboard,
      );
    });

    test('initial location is still the splash on mobile', () {
      AppPlatform.isWebOverride = false;
      expect(AppRouter.initialLocation, RouteNames.splash);
    });
  });

  group('Mobile behaviour is unchanged', () {
    test('signed-out visitor still lands on the mobile login', () {
      AppPlatform.isWebOverride = false;
      expect(authDataSource.isLoggedIn, isFalse);
      expect(AuthRouteGuard.resolveAuthDestination(), RouteNames.auth);
    });

    testWidgets('mobile routes behave exactly as before', (tester) async {
      AppPlatform.isWebOverride = false;
      final context = await pumpContext(tester);
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.auth)),
        isNull,
      );
      expect(
        await AuthRouteGuard.guardRoute(
            context, createMockState(RouteNames.customerHome)),
        RouteNames.auth,
      );
    });
  });
}
