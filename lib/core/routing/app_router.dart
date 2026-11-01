import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_route_guard.dart';
import 'route_names.dart';
import '../../features/auth/presentation/views/splash_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/onboarding_profile_view.dart';
import '../../features/auth/presentation/views/onboarding_role_view.dart';
import '../../features/discovery/presentation/views/customer_location_prompt_view.dart';
import '../../features/discovery/presentation/views/customer_home_view.dart';
import '../../features/discovery/presentation/views/customer_home_map_view.dart';
import '../../features/trust/presentation/views/customer_documents_view.dart';
import '../../features/customer/presentation/customer_flow_view.dart';
import '../../features/owner/presentation/views/owner_onboarding_view.dart';
import '../../features/owner/presentation/views/owner_fleet_view.dart';
import '../../features/owner/presentation/owner_flow_view.dart';
import '../../features/admin/presentation/admin_flow_view.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNav');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    redirect: AuthRouteGuard.guardRoute,
    routes: [
      // Splash Screen
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashView(),
      ),

      // Authentication & Onboarding Routes
      GoRoute(
        path: RouteNames.auth,
        builder: (context, state) => LoginView(
          onSignedIn: () => router.go(AuthRouteGuard.resolveAuthDestination()),
        ),
      ),
      GoRoute(
        path: RouteNames.onboardingProfile,
        builder: (context, state) => OnboardingProfileView(
          onProfileCompleted: () => router.go(RouteNames.onboardingRole),
        ),
      ),
      GoRoute(
        path: RouteNames.onboardingRole,
        builder: (context, state) => OnboardingRoleView(
          onRoleLocked: (role) {
            if (role == 'customer') {
              router.go(RouteNames.customerLocationPrompt);
            } else if (role == 'owner') {
              router.go(RouteNames.ownerOnboarding);
            } else {
              router.go(RouteNames.adminDashboard);
            }
          },
        ),
      ),

      // Customer Onboarding Location Prompt
      GoRoute(
        path: RouteNames.customerLocationPrompt,
        builder: (context, state) => const CustomerLocationPromptView(),
      ),

      // Customer Routes
      GoRoute(
        path: RouteNames.customerHome,
        builder: (context, state) => const CustomerHomeView(),
      ),
      GoRoute(
        path: RouteNames.customerHomeMap,
        builder: (context, state) => const CustomerHomeMapView(),
      ),
      GoRoute(
        path: RouteNames.customerVehicleDetail,
        builder: (context, state) =>
            const CustomerFlowView(initialAnchor: 'ANC-02'),
      ),
      GoRoute(
        path: RouteNames.customerReviewBooking,
        builder: (context, state) =>
            const CustomerFlowView(initialAnchor: 'ANC-04'),
      ),
      GoRoute(
        path: RouteNames.customerPaymentProof,
        builder: (context, state) =>
            const CustomerFlowView(initialAnchor: 'ANC-03'),
      ),
      GoRoute(
        path: RouteNames.customerPickupPass,
        builder: (context, state) =>
            const CustomerFlowView(initialAnchor: 'ANC-05'),
      ),
      GoRoute(
        path: RouteNames.customerActiveTrip,
        builder: (context, state) =>
            const CustomerFlowView(initialAnchor: 'ANC-06'),
      ),
      GoRoute(
        path: RouteNames.customerRateTrip,
        builder: (context, state) =>
            const CustomerFlowView(initialAnchor: 'ANC-08'),
      ),
      GoRoute(
        path: RouteNames.customerKyc,
        builder: (context, state) => const CustomerDocumentsView(),
      ),

      // Owner Routes
      GoRoute(
        path: RouteNames.ownerOnboarding,
        builder: (context, state) => const OwnerOnboardingView(),
      ),
      GoRoute(
        path: RouteNames.ownerDashboard,
        builder: (context, state) =>
            const OwnerFlowView(initialAnchor: 'ANC-10'),
      ),
      GoRoute(
        path: RouteNames.ownerFleet,
        builder: (context, state) => const OwnerFleetView(),
      ),
      GoRoute(
        path: RouteNames.ownerRates,
        builder: (context, state) =>
            const OwnerFlowView(initialAnchor: 'ANC-12'),
      ),
      GoRoute(
        path: RouteNames.ownerRequests,
        builder: (context, state) =>
            const OwnerFlowView(initialAnchor: 'ANC-13'),
      ),
      GoRoute(
        path: RouteNames.ownerHandover,
        builder: (context, state) =>
            const OwnerFlowView(initialAnchor: 'ANC-14'),
      ),
      GoRoute(
        path: RouteNames.ownerReturn,
        builder: (context, state) =>
            const OwnerFlowView(initialAnchor: 'ANC-15'),
      ),
      GoRoute(
        path: RouteNames.ownerBlacklist,
        builder: (context, state) =>
            const OwnerFlowView(initialAnchor: 'ANC-16'),
      ),

      // Super Admin Web Routes
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) =>
            const AdminFlowView(initialAnchor: 'ANC-17'),
      ),
      GoRoute(
        path: RouteNames.adminShops,
        builder: (context, state) =>
            const AdminFlowView(initialAnchor: 'ANC-18'),
      ),
      GoRoute(
        path: RouteNames.adminBlacklist,
        builder: (context, state) =>
            const AdminFlowView(initialAnchor: 'ANC-19'),
      ),
      GoRoute(
        path: RouteNames.adminSubscriptions,
        builder: (context, state) =>
            const AdminFlowView(initialAnchor: 'ANC-20'),
      ),
    ],
  );
}

