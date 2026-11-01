import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/routing/auth_route_guard.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AuthRemoteDataSource authDataSource;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => prefs);

    authDataSource = AuthRemoteDataSource(prefs: prefs);
    sl.registerLazySingleton<AuthRemoteDataSource>(() => authDataSource);
  });

  tearDown(() async {
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

  group('Auth Setup Requirement 1: If already logged in, go to relevant dashboard (customer / owner)', () {
    testWidgets('Customer with completed onboarding routes to Customer Home dashboard', (tester) async {
      await authDataSource.setLoggedIn(true);
      await authDataSource.saveProfileInfo(fullName: 'Ahmed Raza', phone: '03001234567');
      await authDataSource.assignPermanentRole(role: 'customer', fullName: 'Ahmed Raza', phone: '03001234567');
      await authDataSource.setOnboardingCompleted(true);

      expect(authDataSource.isLoggedIn, isTrue);
      expect(authDataSource.isOnboardingCompleted, isTrue);
      expect(authDataSource.lockedRole, 'customer');

      expect(AuthRouteGuard.resolveDashboardRoute(), RouteNames.customerHome);
      expect(AuthRouteGuard.resolveAuthDestination(), RouteNames.customerHome);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      // Guard redirects auth or onboarding screen to customer dashboard
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.auth)),
        RouteNames.customerHome,
      );
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.onboardingProfile)),
        RouteNames.customerHome,
      );
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.customerHome)),
        isNull,
      );
    });

    testWidgets('Fleet Owner with completed onboarding routes to Owner Fleet dashboard', (tester) async {
      await authDataSource.setLoggedIn(true);
      await authDataSource.saveProfileInfo(fullName: 'Kashif Mehmood', phone: '03219876543');
      await authDataSource.assignPermanentRole(role: 'owner', fullName: 'Kashif Mehmood', phone: '03219876543');
      await authDataSource.setOnboardingCompleted(true);

      expect(authDataSource.isLoggedIn, isTrue);
      expect(authDataSource.isOnboardingCompleted, isTrue);
      expect(authDataSource.lockedRole, 'owner');

      expect(AuthRouteGuard.resolveDashboardRoute(), RouteNames.ownerFleet);
      expect(AuthRouteGuard.resolveAuthDestination(), RouteNames.ownerFleet);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.auth)),
        RouteNames.ownerFleet,
      );
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.ownerFleet)),
        isNull,
      );
    });
  });

  group('Auth Setup Requirement 2: Only logged-in users can use app (requires login / onboarding)', () {
    testWidgets('Unauthenticated user is restricted from accessing customer or owner routes', (tester) async {
      expect(authDataSource.isLoggedIn, isFalse);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      // Attempting to access customer home without login
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.customerHome)),
        RouteNames.auth,
      );

      // Attempting to access owner fleet without login
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.ownerFleet)),
        RouteNames.auth,
      );

      // Attempting to access onboarding directly without login
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.onboardingProfile)),
        RouteNames.auth,
      );

      // Splash and auth screens are allowed
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.splash)),
        isNull,
      );
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.auth)),
        isNull,
      );
    });
  });

  group('Auth Setup Requirement 3: Registered users with incomplete onboarding are directed to onboarding', () {
    testWidgets('Logged in user without profile info is directed to Onboarding Profile (Step 1)', (tester) async {
      await authDataSource.setLoggedIn(true);

      expect(authDataSource.isLoggedIn, isTrue);
      expect(authDataSource.hasProfileInfo, isFalse);
      expect(authDataSource.isOnboardingCompleted, isFalse);

      expect(AuthRouteGuard.resolvePendingOnboardingRoute(), RouteNames.onboardingProfile);
      expect(AuthRouteGuard.resolveAuthDestination(), RouteNames.onboardingProfile);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      // Premature access to customer dashboard redirects to Step 1 Profile
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.customerHome)),
        RouteNames.onboardingProfile,
      );
      // Accessing auth redirects to pending Step 1 Profile
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.auth)),
        RouteNames.onboardingProfile,
      );
      // Staying on onboarding profile is permitted
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.onboardingProfile)),
        isNull,
      );
    });

    testWidgets('Logged in user with profile info but no role is directed to Onboarding Role (Step 2)', (tester) async {
      await authDataSource.setLoggedIn(true);
      await authDataSource.saveProfileInfo(fullName: 'Zainab Bibi', phone: '03331122334');

      expect(authDataSource.isLoggedIn, isTrue);
      expect(authDataSource.hasProfileInfo, isTrue);
      expect(authDataSource.lockedRole, isNull);
      expect(authDataSource.isOnboardingCompleted, isFalse);

      expect(AuthRouteGuard.resolvePendingOnboardingRoute(), RouteNames.onboardingRole);
      expect(AuthRouteGuard.resolveAuthDestination(), RouteNames.onboardingRole);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      // Attempting to jump to customer home redirects to Step 2 Role
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.customerHome)),
        RouteNames.onboardingRole,
      );
      // Allowed on onboarding role
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.onboardingRole)),
        isNull,
      );
    });

    testWidgets('Logged in owner with incomplete showroom KYC is directed to Owner Onboarding', (tester) async {
      await authDataSource.setLoggedIn(true);
      await authDataSource.saveProfileInfo(fullName: 'Farhan Ali', phone: '03451122334');
      await authDataSource.assignPermanentRole(role: 'owner', fullName: 'Farhan Ali', phone: '03451122334');
      // Intentionally NOT marking onboarding completed

      expect(authDataSource.isLoggedIn, isTrue);
      expect(authDataSource.lockedRole, 'owner');
      expect(authDataSource.isOnboardingCompleted, isFalse);

      expect(AuthRouteGuard.resolvePendingOnboardingRoute(), RouteNames.ownerOnboarding);
      expect(AuthRouteGuard.resolveAuthDestination(), RouteNames.ownerOnboarding);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      // Attempting to access fleet dashboard redirects to Owner Onboarding
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.ownerFleet)),
        RouteNames.ownerOnboarding,
      );
      // Allowed on owner onboarding
      expect(
        AuthRouteGuard.guardRoute(context, createMockState(RouteNames.ownerOnboarding)),
        isNull,
      );
    });
  });
}
