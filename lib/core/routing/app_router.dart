import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_route_guard.dart';
import 'route_names.dart';
import '../../core/utils/current_shop.dart';
import '../../features/auth/presentation/views/splash_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/onboarding_profile_view.dart';
import '../../features/auth/presentation/views/onboarding_role_view.dart';
import '../../features/bookings/presentation/views/owner_payment_accounts_view.dart';
import '../../features/bookings/presentation/views/payment_proof_upload_view.dart';
import '../../features/discovery/presentation/views/customer_location_prompt_view.dart';
import '../../features/discovery/presentation/views/customer_home_view.dart';
import '../../features/discovery/presentation/views/customer_home_map_view.dart';
import '../../features/trust/presentation/views/customer_documents_view.dart';
import '../../features/customer/presentation/customer_flow_view.dart';
import '../../features/owner/presentation/views/owner_add_vehicle_view.dart';
import '../../features/owner/presentation/views/owner_booking_requests_view.dart';
import '../../features/owner/presentation/views/owner_contract_view.dart';
import '../../features/owner/presentation/views/owner_customer_rating_view.dart';
import '../../features/owner/presentation/views/owner_customer_scan_view.dart';
import '../../features/owner/presentation/views/owner_dashboard_view.dart';
import '../../features/owner/presentation/views/owner_handover_signature_view.dart';
import '../../features/owner/presentation/views/owner_manual_booking_view.dart';
import '../../features/owner/presentation/views/owner_onboarding_view.dart';
import '../../features/owner/presentation/views/owner_rate_matrix_view.dart';
import '../../features/owner/presentation/views/owner_return_settlement_view.dart';
import '../../features/owner/presentation/views/owner_subscription_view.dart';
import '../../features/owner/presentation/views/owner_whatsapp_logs_view.dart';
import '../../features/owner/presentation/views/owner_fleet_view.dart';
import '../../features/owner/presentation/widgets/owner_route_loaders.dart';
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

      // Owner Routes — Phase A (A1): real views, no mock flow view.
      // Views that take a booking/vehicle id load the entity first via
      // BookingRouteLoader / VehicleRouteLoader (loading + not-found states).
      GoRoute(
        path: RouteNames.ownerOnboarding,
        builder: (context, state) => const OwnerOnboardingView(),
      ),
      GoRoute(
        path: RouteNames.ownerDashboard,
        builder: (context, state) =>
            OwnerDashboardView(shopId: currentShopId()),
      ),
      GoRoute(
        path: RouteNames.ownerFleet,
        builder: (context, state) => const OwnerFleetView(),
      ),
      GoRoute(
        path: RouteNames.ownerAddVehicle,
        builder: (context, state) => const OwnerAddVehicleView(),
      ),
      GoRoute(
        path: RouteNames.ownerRates,
        // Rates are per vehicle: pick a vehicle in the fleet first.
        redirect: (context, state) => RouteNames.ownerFleet,
      ),
      GoRoute(
        path: RouteNames.ownerRatesVehicle,
        builder: (context, state) => VehicleRouteLoader(
          vehicleId: state.pathParameters['vehicleId']!,
          shopId: currentShopId(),
          builder: (context, vehicle) => OwnerRateMatrixView(
            vehicle: vehicle,
            onBack: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.ownerRequests,
        builder: (context, state) =>
            OwnerBookingRequestsView(shopId: currentShopId()),
      ),
      GoRoute(
        path: RouteNames.ownerRequestsDetail,
        builder: (context, state) => BookingRouteLoader(
          bookingId: state.pathParameters['id']!,
          builder: (context, booking) => OwnerPaymentAccountsView(
            booking: booking,
            onProceedToUploadProof: () => context.push(
              RouteNames.ownerPaymentProof
                  .replaceFirst(':id', booking.bookingId),
            ),
            onBack: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.ownerManualBooking,
        builder: (context, state) => const OwnerManualBookingView(),
      ),
      GoRoute(
        path: RouteNames.ownerPaymentProof,
        builder: (context, state) => BookingRouteLoader(
          bookingId: state.pathParameters['id']!,
          builder: (context, booking) => PaymentProofUploadView(
            booking: booking,
            onBack: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.ownerHandover,
        builder: (context, state) => BookingRouteLoader(
          bookingId: state.pathParameters['id']!,
          builder: (context, booking) => OwnerHandoverSignatureView(
            booking: booking,
            onBack: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.ownerReturn,
        builder: (context, state) => BookingRouteLoader(
          bookingId: state.pathParameters['id']!,
          builder: (context, booking) => OwnerReturnSettlementView(
            booking: booking,
            onBack: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.ownerContract,
        builder: (context, state) => BookingRouteLoader(
          bookingId: state.pathParameters['id']!,
          builder: (context, booking) => OwnerContractView(
            booking: booking,
            onBack: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.ownerRateCustomer,
        builder: (context, state) => BookingRouteLoader(
          bookingId: state.pathParameters['id']!,
          builder: (context, booking) => OwnerCustomerRatingView(
            booking: booking,
            onBack: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.ownerCustomerScan,
        builder: (context, state) => const OwnerCustomerScanView(),
      ),
      GoRoute(
        path: RouteNames.ownerBlacklist,
        // Interim (A1): the scan view is the KYC & Blacklist Radar.
        // A dedicated blacklist list lands in Phase C (C4).
        builder: (context, state) => const OwnerCustomerScanView(),
      ),
      GoRoute(
        path: RouteNames.ownerSubscription,
        builder: (context, state) => const OwnerSubscriptionView(),
      ),
      GoRoute(
        path: RouteNames.ownerWhatsappLogs,
        builder: (context, state) => const OwnerWhatsAppLogsView(),
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

