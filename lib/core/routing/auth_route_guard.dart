import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import 'route_names.dart';

class AuthRouteGuard {
  static bool get isLoggedIn {
    if (!sl.isRegistered<AuthRemoteDataSource>()) return false;
    return sl<AuthRemoteDataSource>().isLoggedIn;
  }

  static bool get isOnboardingCompleted {
    if (!sl.isRegistered<AuthRemoteDataSource>()) return false;
    return sl<AuthRemoteDataSource>().isOnboardingCompleted;
  }

  static String? get lockedRole {
    if (!sl.isRegistered<AuthRemoteDataSource>()) return null;
    return sl<AuthRemoteDataSource>().lockedRole;
  }

  static bool get hasProfileInfo {
    if (!sl.isRegistered<AuthRemoteDataSource>()) return false;
    return sl<AuthRemoteDataSource>().hasProfileInfo;
  }

  /// Resolves the relevant dashboard based on user role:
  /// - 'owner' -> RouteNames.ownerFleet
  /// - 'admin' / 'super_admin' -> RouteNames.adminDashboard
  /// - default / 'customer' -> RouteNames.customerHome
  static String resolveDashboardRoute([String? role]) {
    final effectiveRole = role ?? lockedRole;
    if (effectiveRole == 'owner') {
      return RouteNames.ownerFleet;
    } else if (effectiveRole == 'admin' || effectiveRole == 'super_admin') {
      return RouteNames.adminDashboard;
    }
    return RouteNames.customerHome;
  }

  /// Resolves the current pending onboarding step for registered users:
  /// - If profile info (name, phone) is missing -> RouteNames.onboardingProfile
  /// - If role is not selected -> RouteNames.onboardingRole
  /// - If role is 'owner' -> RouteNames.ownerOnboarding
  /// - Otherwise -> RouteNames.customerLocationPrompt
  static String resolvePendingOnboardingRoute() {
    if (!hasProfileInfo) {
      return RouteNames.onboardingProfile;
    }
    final role = lockedRole;
    if (role == null) {
      return RouteNames.onboardingRole;
    }
    if (role == 'owner') {
      return RouteNames.ownerOnboarding;
    }
    return RouteNames.customerLocationPrompt;
  }

  /// Resolves the post-auth or post-splash destination for any auth state:
  /// 1. If not logged in -> RouteNames.auth
  /// 2. If logged in and onboarding completed -> Relevant dashboard
  /// 3. If logged in but onboarding incomplete -> Pending onboarding step
  static String resolveAuthDestination() {
    if (!isLoggedIn) return RouteNames.auth;
    if (isOnboardingCompleted) {
      return resolveDashboardRoute();
    }
    return resolvePendingOnboardingRoute();
  }

  /// Route guard redirect handler for GoRouter
  static String? guardRoute(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    // 1. Splash screen is allowed to run its animation freely
    if (location == RouteNames.splash) {
      return null;
    }

    final loggedIn = isLoggedIn;

    // 2. Unauthenticated user: only login/auth is allowed
    // Requirement 2: only logged in users can use app (requires login / onboarding)
    if (!loggedIn) {
      if (location != RouteNames.auth) {
        return RouteNames.auth;
      }
      return null;
    }

    // 3. User is logged in, check onboarding status
    final onboardingDone = isOnboardingCompleted;

    if (!onboardingDone) {
      // Requirement 3: a user is registered but have not completed onboarding
      // should be directed to onboarding
      const allowedOnboardingRoutes = [
        RouteNames.onboardingProfile,
        RouteNames.onboardingRole,
        RouteNames.ownerOnboarding,
        RouteNames.customerLocationPrompt,
      ];

      // If at auth screen or trying to access main app dashboards prematurely
      if (location == RouteNames.auth || !allowedOnboardingRoutes.contains(location)) {
        return resolvePendingOnboardingRoute();
      }

      return null;
    }

    // 4. Authenticated user with completed onboarding:
    // Requirement 1: if already logged in go to relevant dashboard customer / owner
    const unneededWhenOnboarded = [
      RouteNames.auth,
      RouteNames.onboardingProfile,
      RouteNames.onboardingRole,
      RouteNames.ownerOnboarding,
    ];

    if (unneededWhenOnboarded.contains(location)) {
      return resolveDashboardRoute();
    }

    return null;
  }
}

