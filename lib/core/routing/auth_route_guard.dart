import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart';
import '../platform/app_platform.dart';
import '../../features/admin/data/services/admin_session.dart';
import '../../features/admin/domain/admin_permissions.dart';
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
  ///
  /// Web is the admin panel (mobile is customer + owner): a signed-out
  /// web visitor belongs on the admin login, and a signed-in user
  /// belongs on the admin dashboard. The router guard enforces the
  /// admin role + TOTP on /admin routes, so a non-admin is bounced
  /// back to the admin login from there.
  static String resolveAuthDestination() {
    if (AppPlatform.isWeb) {
      return isLoggedIn ? RouteNames.adminDashboard : RouteNames.adminLogin;
    }
    if (!isLoggedIn) return RouteNames.auth;
    if (isOnboardingCompleted) {
      return resolveDashboardRoute();
    }
    return resolvePendingOnboardingRoute();
  }

  /// Route guard redirect handler for GoRouter. Async because the
  /// admin branch resolves the admin role from Firestore (cached per
  /// session by AdminSession, so it reads once, not on every tap).
  static Future<String?> guardRoute(
      BuildContext context, GoRouterState state) async {
    final location = state.matchedLocation;

    // 1. Splash screen is allowed to run its animation freely
    if (location == RouteNames.splash) {
      return null;
    }

    // 1a. Web build is the admin panel only (mobile is customer +
    // owner): every non-/admin location on web belongs on the admin
    // login. An already-signed-in admin is auto-continued from there
    // (AdminLoginView resolves their profile); anyone else sees the
    // not-an-admin card. Splash is exempt above — it navigates via
    // resolveAuthDestination, which has its own web branch.
    if (AppPlatform.isWeb && !location.startsWith('/admin')) {
      return RouteNames.adminLogin;
    }

    // 1b. Admin panel (Phase A, A3): the login screen is always
    // reachable; every other /admin route needs a signed-in admin who
    // has passed the TOTP step. Admins never go through the
    // customer/owner onboarding — this branch runs before it.
    if (location.startsWith('/admin')) {
      if (location == RouteNames.adminLogin) {
        return null;
      }
      if (!isLoggedIn) {
        return RouteNames.adminLogin;
      }
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        user = null;
      }
      if (user == null) {
        return RouteNames.adminLogin;
      }
      final adminRole = await AdminSession.resolveAdminRole(user);
      if (adminRole == null) {
        return RouteNames.adminLogin;
      }
      if (await AdminSession.adminNeedsTotp(user)) {
        return RouteNames.adminLogin;
      }
      // F-C1 — per-route permission redirects, following the
      // KYC-review pattern (item 6): a role that may not use a
      // section never renders it, and a direct URL is bounced to
      // the dashboard instead. The views and data sources check
      // the same permissions again as the backstop.
      //
      // Routes not listed here stay open to every admin role:
      // dashboard, customers, bookings, disputes and tickets are
      // mixed read + triage sections — support holds
      // manageDisputes / triageTicket, and the decision actions
      // inside them (decideDispute, resolveTicket) are gated in
      // the sheets and data sources. Activity log and reports are
      // read-only for every admin role (viewActivityLog).
      //
      // Reviews moderation has no dedicated matrix permission, so
      // it rides on managePlatform (a platform-level decision:
      // super admin + operations only) — see
      // AdminPermissionCheck for the same mapping in the views.
      const routePermissions = <String, AdminPermission>{
        RouteNames.adminTeam: AdminPermission.manageTeam,
        RouteNames.adminInviteAccept: AdminPermission.manageTeam,
        RouteNames.adminShops: AdminPermission.decideVendor,
        RouteNames.adminCars: AdminPermission.decideVendor,
        RouteNames.adminKycReview: AdminPermission.decideKyc,
        RouteNames.adminBlacklist: AdminPermission.manageBlacklist,
        RouteNames.adminSettings: AdminPermission.managePlatform,
        RouteNames.adminAnnouncements: AdminPermission.managePlatform,
        RouteNames.adminReviews: AdminPermission.managePlatform,
        RouteNames.adminSubscriptions:
            AdminPermission.manageSubscriptions,
        RouteNames.adminApkDownload: AdminPermission.downloadApk,
      };
      for (final entry in routePermissions.entries) {
        final isRoute = location == entry.key ||
            location.startsWith('${entry.key}/');
        if (isRoute &&
            !AdminPermissions.can(adminRole, entry.value)) {
          return RouteNames.adminDashboard;
        }
      }
      return null;
    }

    final loggedIn = isLoggedIn;

    // 2. Unauthenticated user: only login/auth is allowed, plus the
    // signed-out confirmation screen (reached right after sign-out,
    // while already logged out — same exemption pattern as splash).
    // Requirement 2: only logged in users can use app (requires login / onboarding)
    if (!loggedIn) {
      if (location != RouteNames.auth &&
          location != RouteNames.ownerSignedOut) {
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

