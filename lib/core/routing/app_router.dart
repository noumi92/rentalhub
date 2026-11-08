import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_shell.dart';
import '../widgets/app_shell_nav.dart';
import '../../l10n/app_localizations.dart';
import 'auth_route_guard.dart';
import 'route_names.dart';
import '../../core/utils/current_shop.dart';
import '../../features/auth/presentation/utils/sign_out_helper.dart';
import '../../features/auth/presentation/views/splash_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/onboarding_profile_view.dart';
import '../../features/auth/presentation/views/onboarding_role_view.dart';
import '../../features/bookings/presentation/views/booking_approved_view.dart';
import '../../features/bookings/presentation/views/booking_success_view.dart';
import '../../features/bookings/presentation/views/owner_payment_accounts_view.dart';
import '../../features/bookings/presentation/views/payment_proof_upload_view.dart';
import '../../features/bookings/presentation/views/pickup_countdown_pass_view.dart';
import '../../features/bookings/presentation/views/rent_package_picker_view.dart';
import '../../features/bookings/presentation/views/review_booking_request_view.dart';
import '../../features/customer/presentation/views/customer_booking_detail_view.dart';
import '../../features/customer/presentation/views/customer_bookings_view.dart';
import '../../features/customer/presentation/widgets/customer_route_loaders.dart';
import '../../features/customer/presentation/widgets/customer_support_badge.dart';
import '../../features/customer/presentation/views/customer_cancel_booking_view.dart';
import '../../features/customer/presentation/views/customer_active_trip_view.dart';
import '../../features/customer/presentation/views/customer_dispute_view.dart';
import '../../features/customer/presentation/views/customer_profile_view.dart';
import '../../features/customer/presentation/views/customer_rate_trip_view.dart';
import '../../features/customer/presentation/views/customer_reputation_view.dart';
import '../../features/customer/presentation/views/customer_saved_shops_view.dart';
import '../../features/customer/presentation/views/customer_settings_view.dart';
import '../../features/customer/presentation/views/customer_sos_view.dart';
import '../../features/customer/presentation/views/customer_support_view.dart';
import '../../features/customer/presentation/views/customer_wallet_view.dart';
import '../../features/discovery/presentation/views/customer_location_prompt_view.dart';
import '../../features/discovery/presentation/views/customer_home_view.dart';
import '../../features/discovery/presentation/views/customer_home_map_view.dart';
import '../../features/discovery/presentation/views/shop_cars_view.dart';
import '../../features/discovery/presentation/views/shop_detail_view.dart';
import '../../features/discovery/presentation/views/vehicle_detail_view.dart';
import '../../features/trust/presentation/views/customer_documents_view.dart';
import '../../features/owner/presentation/views/owner_add_customer_view.dart';
import '../../features/owner/presentation/views/owner_add_vehicle_view.dart';
import '../../features/owner/presentation/views/owner_booking_requests_view.dart';
import '../../features/owner/presentation/views/owner_contract_view.dart';
import '../../features/owner/presentation/views/owner_qr_scan_view.dart';
import '../../features/owner/presentation/views/owner_customer_rating_view.dart';
import '../../features/owner/presentation/views/owner_blacklist_view.dart';
import '../../features/owner/presentation/views/owner_customer_scan_view.dart';
import '../../features/owner/presentation/views/owner_customers_list_view.dart';
import '../../features/owner/presentation/views/owner_payment_verification_view.dart';
import '../../features/owner/presentation/views/owner_dashboard_view.dart';
import '../../features/owner/presentation/views/owner_fixed_routes_view.dart';
import '../../features/owner/presentation/views/owner_handover_signature_view.dart';
import '../../features/owner/presentation/views/owner_manual_booking_view.dart';
import '../../features/owner/presentation/views/owner_onboarding_view.dart';
import '../../features/owner/presentation/views/owner_rate_matrix_view.dart';
import '../../features/owner/presentation/views/owner_return_settlement_view.dart';
import '../../features/owner/presentation/views/owner_car_pnl_view.dart';
import '../../features/owner/presentation/views/owner_cash_closing_view.dart';
import '../../features/owner/presentation/views/owner_dues_view.dart';
import '../../features/owner/presentation/views/owner_finance_view.dart';
import '../../features/owner/presentation/views/owner_disputes_view.dart';
import '../../features/owner/presentation/views/owner_notifications_view.dart';
import '../../features/owner/presentation/views/owner_settings_view.dart';
import '../../features/owner/presentation/views/owner_subscription_view.dart';
import '../../features/owner/presentation/views/owner_vehicle_calendar_view.dart';
import '../../features/owner/presentation/views/owner_whatsapp_logs_view.dart';
import '../../features/owner/presentation/views/owner_fleet_view.dart';
import '../../features/owner/presentation/widgets/owner_route_loaders.dart';
import '../../features/owner/presentation/widgets/owner_requests_badge.dart';
import '../../features/settings/presentation/views/sync_details_view.dart';
import '../../features/admin/presentation/views/admin_activity_log_view.dart';
import '../../features/admin/presentation/views/admin_cars_view.dart';
import '../../features/admin/presentation/views/admin_customer_detail_view.dart';
import '../../features/admin/presentation/views/admin_customers_view.dart';
import '../../features/admin/presentation/views/admin_booking_detail_view.dart';
import '../../features/admin/presentation/views/admin_bookings_view.dart';
import '../../features/admin/presentation/views/admin_disputes_view.dart';
import '../../features/admin/presentation/views/admin_reviews_view.dart';
import '../../features/admin/presentation/views/admin_announcements_view.dart';
import '../../features/admin/presentation/views/admin_platform_settings_view.dart';
import '../../features/admin/presentation/views/admin_reports_view.dart';
import '../../features/admin/presentation/views/admin_tickets_view.dart';
import '../../features/admin/presentation/views/admin_shop_approvals_view.dart';
import '../../features/admin/presentation/views/admin_shop_detail_view.dart';
import '../../features/admin/presentation/views/admin_shops_view.dart';
import '../../features/admin/presentation/views/admin_blacklist_tribunal_view.dart';
import '../../features/admin/presentation/views/admin_coming_soon_view.dart';
import '../../features/admin/presentation/views/admin_dashboard_view.dart';
import '../../features/admin/presentation/views/admin_login_view.dart';
import '../../features/admin/presentation/views/admin_team_view.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNav');


  /// Phase C (C1/C3): the five customer tabs. Support carries the live
  /// replied-ticket badge; the other tabs have plain icons.
  /// Phase F: each tab carries an l10nKey — the label renders in the
  /// current locale (the plain `label` stays the English fallback).
  static final customerTabs = <ShellNavItem>[
    const ShellNavItem(
        icon: Icon(Icons.home_rounded), label: 'Home', l10nKey: 'navHome'),
    const ShellNavItem(
        icon: Icon(Icons.receipt_long_rounded),
        label: 'Bookings',
        l10nKey: 'navBookings'),
    const ShellNavItem(
        icon: Icon(Icons.account_balance_wallet_rounded),
        label: 'Wallet',
        l10nKey: 'navWallet'),
    ShellNavItem(
        icon: CustomerSupportBadge(
            icon: const Icon(Icons.support_agent_rounded)),
        label: 'Support',
        l10nKey: 'navSupport'),
    const ShellNavItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
        l10nKey: 'navProfile'),
  ];

  /// Phase C (C1/C3): the five owner tabs. Requests carries the live
  /// pending-request badge and is labelled "Requests" (it routes to
  /// /owner/requests — the old "Bookings" label lied about the
  /// destination). The other tabs have plain icons.
  /// Phase F: labels are localized via l10nKey (see customerTabs).
  static final ownerTabs = <ShellNavItem>[
    const ShellNavItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
        l10nKey: 'navDashboard'),
    const ShellNavItem(
        icon: Icon(Icons.directions_car_rounded),
        label: 'Fleet',
        l10nKey: 'navFleet'),
    ShellNavItem(
        icon: OwnerRequestsBadge(
            icon: const Icon(Icons.receipt_long_rounded)),
        label: 'Requests',
        l10nKey: 'navRequests'),
    const ShellNavItem(
        icon: Icon(Icons.people_rounded),
        label: 'Customers',
        l10nKey: 'navCustomers'),
    const ShellNavItem(
        icon: Icon(Icons.settings_rounded),
        label: 'Settings',
        l10nKey: 'navSettings'),
  ];

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    redirect: AuthRouteGuard.guardRoute,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashView(),
      ),
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
      GoRoute(
        path: RouteNames.customerLocationPrompt,
        builder: (context, state) => const CustomerLocationPromptView(),
      ),

      // Phase C (C1): customer shell — five branches, one per tab.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
              navigationShell: navigationShell,
              tabs: customerTabs,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              // Home: customerHome
              GoRoute(
                path: RouteNames.customerHome,
                builder: (context, state) => const CustomerHomeView(),
              ),
              // Home: customerHomeMap
              GoRoute(
                path: RouteNames.customerHomeMap,
                builder: (context, state) => const CustomerHomeMapView(),
              ),
              // Home: customerShopDetail
              GoRoute(
                path: RouteNames.customerShopDetail,
                builder: (context, state) => ShopRouteLoader(
                  shopId: state.pathParameters['shopId']!,
                  builder: (context, shop) => ShopDetailView(
                    shop: shop,
                    onVehicleSelected: (vehicle) => context.push(
                      RouteNames.customerVehicleDetail
                          .replaceFirst(':id', vehicle.vehicleId),
                    ),
                    onViewAllCars: () => context.push(
                      RouteNames.customerShopCars
                          .replaceFirst(':shopId', shop.shopId),
                    ),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Home: customerShopCars
              GoRoute(
                // B3: the shop's full fleet with category filters — reachable
                // from the shop detail screen.
                path: RouteNames.customerShopCars,
                builder: (context, state) => ShopRouteLoader(
                  shopId: state.pathParameters['shopId']!,
                  builder: (context, shop) => ShopCarsView(
                    shopId: shop.shopId,
                    shopName: shop.shopName,
                    onCarSelected: (vehicle) => context.push(
                      RouteNames.customerVehicleDetail
                          .replaceFirst(':id', vehicle.vehicleId),
                    ),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Home: customerVehicleDetail
              GoRoute(
                path: RouteNames.customerVehicleDetail,
                builder: (context, state) => CustomerVehicleRouteLoader(
                  vehicleId: state.pathParameters['id']!,
                  builder: (context, vehicle, shopName, shopPhone) =>
                      VehicleDetailView(
                    vehicle: vehicle,
                    shopName: shopName,
                    shopPhone: shopPhone,
                    onBookNow: () => context.push(
                      RouteNames.customerPackagePicker
                          .replaceFirst(':vehicleId', vehicle.vehicleId),
                    ),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Home: customerPackagePicker
              GoRoute(
                path: RouteNames.customerPackagePicker,
                builder: (context, state) => CustomerVehicleRouteLoader(
                  vehicleId: state.pathParameters['vehicleId']!,
                  builder: (context, vehicle, shopName, shopPhone) =>
                      RentPackagePickerView(
                    carId: vehicle.vehicleId,
                    carName: vehicle.displayName,
                    plateNumber: vehicle.plateNumber,
                    shopId: vehicle.shopId,
                    shopName: shopName,
                    dailySelfDriveRate: vehicle.rates.daily24,
                    dailyWithDriverRate:
                        vehicle.rates.daily24 + (vehicle.withDriverSurchargePkr ?? 0),
                    hourlyRate: vehicle.rates.hourly1,
                    vehicle: vehicle,
                    onProceedToReview: (draft) => context.push(
                      RouteNames.customerReviewBooking
                          .replaceFirst(':id', vehicle.vehicleId),
                      extra: draft,
                    ),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Home: customerReviewBooking
              GoRoute(
                path: RouteNames.customerReviewBooking,
                builder: (context, state) {
                  final draft = state.extra as Map<String, dynamic>?;
                  if (draft == null) {
                    return _CustomerNoDraftScreen(
                      onBrowseShops: () => context.go(RouteNames.customerHome),
                    );
                  }
                  return ReviewBookingRequestView(
                    bookingDraft: draft,
                    onRequestCreated: (booking) => context.push(
                      RouteNames.customerBookingSuccess
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onBack: () => context.pop(),
                  );
                },
              ),
              // Home: customerBookingSuccess
              GoRoute(
                path: RouteNames.customerBookingSuccess,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => BookingSuccessView(
                    booking: booking,
                    onProceedToPayment: () => context.push(
                      RouteNames.customerPaymentProof
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onViewBookings: () => context.go(RouteNames.customerBookings),
                  ),
                ),
              ),
              // Home: customerActiveTrip
              GoRoute(
                // E3: the dedicated active-trip view (booking + real handover
                // record). The dashboard's active-trip card opens the same
                // screen via the pass route's booking loader.
                path: RouteNames.customerActiveTrip,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => CustomerActiveTripView(
                    booking: booking,
                    onViewPass: () => context.push(
                      RouteNames.customerPickupPass
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Bookings: customerBookings
              GoRoute(
                path: RouteNames.customerBookings,
                builder: (context, state) => CustomerBookingsView(
                  onOpenBookingDetails: (booking) => context.push(
                    RouteNames.customerBookingDetail
                        .replaceFirst(':id', booking.bookingId),
                  ),
                  onPayAdvance: (booking) => context.push(
                    RouteNames.customerBookingApproved
                        .replaceFirst(':id', booking.bookingId),
                  ),
                  onRateTrip: (booking) => context.push(
                    RouteNames.customerRateTrip
                        .replaceFirst(':id', booking.bookingId),
                  ),
                ),
              ),
              // Bookings: customerBookingDetail
              GoRoute(
                path: RouteNames.customerBookingDetail,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => CustomerBookingDetailView(
                    booking: booking,
                    onPayAdvance: () => context.push(
                      RouteNames.customerBookingApproved
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onViewPass: () => context.push(
                      RouteNames.customerPickupPass
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onCancel: () => context.push(
                      RouteNames.customerCancelBooking
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onRateTrip: () => context.push(
                      RouteNames.customerRateTrip
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onFileDispute: () => context.push(
                      '${RouteNames.customerDisputes}?bookingId=${booking.bookingId}',
                    ),
                    onBrowseShops: () => context.go(RouteNames.customerHome),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Bookings: customerBookingApproved
              GoRoute(
                path: RouteNames.customerBookingApproved,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => BookingApprovedView(
                    booking: booking,
                    onPayAdvance: () => context.push(
                      RouteNames.customerPaymentProof
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Bookings: customerPaymentProof
              GoRoute(
                path: RouteNames.customerPaymentProof,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => OwnerPaymentAccountsView(
                    booking: booking,
                    onProceedToUploadProof: () => context.push(
                      RouteNames.customerPaymentProofUpload
                          .replaceFirst(':id', booking.bookingId),
                    ),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Bookings: customerPaymentProofUpload
              GoRoute(
                path: RouteNames.customerPaymentProofUpload,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => PaymentProofUploadView(
                    booking: booking,
                    onProofSubmitted: (_) =>
                        context.go(RouteNames.customerBookings),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Bookings: customerPickupPass
              GoRoute(
                path: RouteNames.customerPickupPass,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => PickupCountdownPassView(
                    booking: booking,
                    onReturnHome: () => context.go(RouteNames.customerHome),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Bookings: customerRateTrip
              GoRoute(
                path: RouteNames.customerRateTrip,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => CustomerRateTripView(
                    booking: booking,
                    onRatingSubmitted: () => context.go(RouteNames.customerBookings),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Bookings: customerCancelBooking
              GoRoute(
                path: RouteNames.customerCancelBooking,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => CustomerCancelBookingView(
                    booking: booking,
                    onCancelled: () => context.go(RouteNames.customerBookings),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Wallet: customerWallet
              GoRoute(
                path: RouteNames.customerWallet,
                builder: (context, state) => const CustomerWalletView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Support: customerSupport
              GoRoute(
                path: RouteNames.customerSupport,
                builder: (context, state) => CustomerSupportView(
                  onFileDispute: () => context.push(RouteNames.customerDisputes),
                  onOpenSos: () => context.push(RouteNames.customerSos),
                ),
              ),
              // Support: customerSos
              GoRoute(
                path: RouteNames.customerSos,
                builder: (context, state) =>
                    CustomerSosView(onBack: () => context.pop()),
              ),
              // Support: customerDisputes
              GoRoute(
                path: RouteNames.customerDisputes,
                builder: (context, state) => CustomerDisputeView(
                  initialBookingId: state.uri.queryParameters['bookingId'],
                  onDisputeSubmitted: () => context.pop(),
                  onBack: () => context.pop(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Profile: customerProfile
              GoRoute(
                path: RouteNames.customerProfile,
                builder: (context, state) => CustomerProfileView(
                  onOpenDocuments: () => context.push(RouteNames.customerKyc),
                  onOpenSavedShops: () => context.push(RouteNames.customerSavedShops),
                  onOpenSettings: () => context.push(RouteNames.customerSettings),
                  onOpenReputation: () => context.push(RouteNames.customerReputation),
                  onSignOut: () => signOutToAuth(context),
                ),
              ),
              // Profile: customerKyc
              GoRoute(
                path: RouteNames.customerKyc,
                builder: (context, state) => const CustomerDocumentsView(),
              ),
              // Profile: customerSettings
              GoRoute(
                path: RouteNames.customerSettings,
                builder: (context, state) => CustomerSettingsView(
                      onBack: () => context.pop(),
                      onSignOut: () => signOutToAuth(context),
                    ),
              ),
              // Profile: customerReputation
              GoRoute(
                path: RouteNames.customerReputation,
                builder: (context, state) =>
                    CustomerReputationView(onBack: () => context.pop()),
              ),
              // Profile: customerSavedShops
              GoRoute(
                path: RouteNames.customerSavedShops,
                builder: (context, state) => CustomerSavedShopsView(
                  // The shop detail belongs to the Home branch: a plain
                  // push here would append it to the Profile branch's
                  // stack and render it under the Profile tab. Switch to
                  // the Home tab first (branch 0), then push the detail
                  // onto the Home branch — on top of the Home root — so
                  // back returns to Home. The push is deferred a frame so
                  // the branch switch has landed; if the user tapped away
                  // in the meantime, their navigation is left alone.
                  onSelectShop: (shop) {
                    final shell = StatefulNavigationShell.maybeOf(context);
                    if (shell == null) {
                      context.push(
                        RouteNames.customerShopDetail
                            .replaceFirst(':shopId', shop.shopId),
                      );
                      return;
                    }
                    shell.goBranch(0, initialLocation: true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!context.mounted) return;
                      if (shell.currentIndex != 0) return;
                      context.push(
                        RouteNames.customerShopDetail
                            .replaceFirst(':shopId', shop.shopId),
                      );
                    });
                  },
                  onBack: () => context.pop(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Phase C (C1): owner shell — five branches, one per tab.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
              navigationShell: navigationShell,
              tabs: ownerTabs,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              // Dashboard: ownerDashboard
              GoRoute(
                path: RouteNames.ownerDashboard,
                builder: (context, state) =>
                    OwnerDashboardView(shopId: currentShopId()),
              ),
              // Dashboard: ownerNotifications
              GoRoute(
                path: RouteNames.ownerNotifications,
                builder: (context, state) => OwnerNotificationsView(
                  shopId: currentShopId(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Fleet: ownerFleet
              GoRoute(
                path: RouteNames.ownerFleet,
                builder: (context, state) => const OwnerFleetView(),
              ),
              // Fleet: ownerAddVehicle
              GoRoute(
                path: RouteNames.ownerAddVehicle,
                builder: (context, state) => const OwnerAddVehicleView(),
              ),
              // Fleet: ownerRatesVehicle
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
              // Fleet: ownerCalendar
              GoRoute(
                path: RouteNames.ownerCalendar,
                builder: (context, state) => VehicleRouteLoader(
                  vehicleId: state.pathParameters['vehicleId']!,
                  shopId: currentShopId(),
                  builder: (context, vehicle) => OwnerVehicleCalendarView(
                    vehicle: vehicle,
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Fleet: ownerFixedRoutes
              GoRoute(
                path: RouteNames.ownerFixedRoutes,
                builder: (context, state) => OwnerFixedRoutesView(
                  shopId: currentShopId(),
                  onBack: () => context.pop(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Requests: ownerRequests
              GoRoute(
                path: RouteNames.ownerRequests,
                builder: (context, state) =>
                    OwnerBookingRequestsView(shopId: currentShopId()),
              ),
              // Requests: ownerRequestsDetail
              GoRoute(
                path: RouteNames.ownerRequestsDetail,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  // Phase B (D3): a submitted proof goes to verification;
                  // anything else shows the payment accounts + proof upload.
                  builder: (context, booking) =>
                      booking.status == 'payment_submitted'
                          ? OwnerPaymentVerificationView(
                              booking: booking,
                              onBack: () => context.pop(),
                            )
                          : OwnerPaymentAccountsView(
                              booking: booking,
                              onProceedToUploadProof: () => context.push(
                                RouteNames.ownerPaymentProof
                                    .replaceFirst(':id', booking.bookingId),
                              ),
                              onBack: () => context.pop(),
                            ),
                ),
              ),
              // Requests: ownerPaymentProof
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
              // Requests: ownerManualBooking — #18: name/phone/CNIC
              // arrive as query params from the Customers list Book
              // action (or the scan view's CNIC-only prefill).
              GoRoute(
                path: RouteNames.ownerManualBooking,
                builder: (context, state) => OwnerManualBookingView(
                  prefilledCnic: state.uri.queryParameters['cnic'],
                  prefilledName: state.uri.queryParameters['name'],
                  prefilledPhone: state.uri.queryParameters['phone'],
                ),
              ),
              // Requests: ownerHandover
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
              // Requests: ownerReturn
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
              // Requests: ownerContract
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
              // Requests: ownerRateCustomer
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
              // Requests: ownerQrScan
              GoRoute(
                path: RouteNames.ownerQrScan,
                builder: (context, state) => const OwnerQrScanView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Customers: ownerCustomers
              GoRoute(
                path: RouteNames.ownerCustomers,
                builder: (context, state) => OwnerCustomersListView(
                  shopId: currentShopId(),
                ),
              ),
              // Customers: ownerCustomerScan
              GoRoute(
                path: RouteNames.ownerCustomerScan,
                builder: (context, state) => const OwnerCustomerScanView(),
              ),
              // Customers: ownerAddCustomer (Phone-test #18: the scan
              // view's Proceed lands here, not in the booking wizard).
              GoRoute(
                path: RouteNames.ownerAddCustomer,
                builder: (context, state) => OwnerAddCustomerView(
                  prefilledCnic: state.uri.queryParameters['cnic'],
                ),
              ),
              // Customers: ownerBlacklist
              GoRoute(
                path: RouteNames.ownerBlacklist,
                // Phase B (C4): the dedicated report form + my-reports list.
                builder: (context, state) => OwnerBlacklistView(
                  shopId: currentShopId(),
                  onBack: () => context.pop(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Settings: ownerSettings
              GoRoute(
                path: RouteNames.ownerSettings,
                builder: (context, state) => const OwnerSettingsView(),
              ),
              // Settings: ownerFinance
              GoRoute(
                path: RouteNames.ownerFinance,
                builder: (context, state) => OwnerFinanceView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerDues
              GoRoute(
                path: RouteNames.ownerDues,
                builder: (context, state) => OwnerDuesView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerCashClosing
              GoRoute(
                path: RouteNames.ownerCashClosing,
                builder: (context, state) => OwnerCashClosingView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerCarPnL
              GoRoute(
                path: RouteNames.ownerCarPnL,
                builder: (context, state) => OwnerCarPnLView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerSubscription
              GoRoute(
                path: RouteNames.ownerSubscription,
                builder: (context, state) => const OwnerSubscriptionView(),
              ),
              // Settings: ownerWhatsappLogs
              GoRoute(
                path: RouteNames.ownerWhatsappLogs,
                builder: (context, state) => const OwnerWhatsAppLogsView(),
              ),
              // Settings: ownerDisputes
              GoRoute(
                path: RouteNames.ownerDisputes,
                builder: (context, state) => OwnerDisputesView(
                  shopId: currentShopId(),
                ),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: RouteNames.ownerOnboarding,
        builder: (context, state) => const OwnerOnboardingView(),
      ),
      GoRoute(
        // Phone-test #4: top-level (not inside a shell branch) so the
        // failed-sync banner and Settings can open it without a tab bar.
        path: RouteNames.syncDetails,
        builder: (context, state) => const SyncDetailsView(),
      ),
      GoRoute(
        path: RouteNames.ownerRates,
        // Rates are per vehicle: pick a vehicle in the fleet first.
        redirect: (context, state) => RouteNames.ownerFleet,
      ),

      // Super Admin Web Routes (Phase A): the login screen is public;
      // every other /admin route is guarded by AuthRouteGuard (admin role
      // + TOTP). The dashboard and blacklist are real; shops and
      // subscriptions are honest placeholders until Phases B and F.
      GoRoute(
        path: RouteNames.adminLogin,
        builder: (context, state) => const AdminLoginView(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardView(),
      ),
      GoRoute(
        path: RouteNames.adminShops,
        builder: (context, state) => const AdminShopsView(),
      ),
      GoRoute(
        path: RouteNames.adminShopDetail,
        builder: (context, state) => AdminShopDetailView(
          shopId: state.pathParameters['shopId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.adminApprovals,
        builder: (context, state) => const AdminShopApprovalsView(),
      ),
      GoRoute(
        path: RouteNames.adminCars,
        builder: (context, state) => const AdminCarsView(),
      ),
      GoRoute(
        path: RouteNames.adminCustomers,
        builder: (context, state) => const AdminCustomersView(),
      ),
      GoRoute(
        path: RouteNames.adminCustomerDetail,
        builder: (context, state) => AdminCustomerDetailView(
          customerId: state.pathParameters['customerId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.adminBookings,
        builder: (context, state) => const AdminBookingsView(),
      ),
      GoRoute(
        path: RouteNames.adminBookingDetail,
        builder: (context, state) => AdminBookingDetailView(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.adminDisputes,
        builder: (context, state) => const AdminDisputesView(),
      ),
      GoRoute(
        path: RouteNames.adminReviews,
        builder: (context, state) => const AdminReviewsView(),
      ),
      GoRoute(
        path: RouteNames.adminTickets,
        builder: (context, state) => const AdminTicketsView(),
      ),
      GoRoute(
        path: RouteNames.adminSettings,
        builder: (context, state) => const AdminPlatformSettingsView(),
      ),
      GoRoute(
        path: RouteNames.adminAnnouncements,
        builder: (context, state) => const AdminAnnouncementsView(),
      ),
      GoRoute(
        path: RouteNames.adminReports,
        builder: (context, state) => const AdminReportsView(),
      ),
      GoRoute(
        path: RouteNames.adminBlacklist,
        builder: (context, state) => const AdminBlacklistTribunalView(),
      ),
      GoRoute(
        path: RouteNames.adminTeam,
        builder: (context, state) => const AdminTeamView(),
      ),
      GoRoute(
        path: RouteNames.adminActivity,
        builder: (context, state) => const AdminActivityLogView(),
      ),
      GoRoute(
        path: RouteNames.adminSubscriptions,
        builder: (context, state) => const AdminComingSoonView(
          activeRoute: RouteNames.adminSubscriptions,
          title: 'Subscriptions',
          subtitle: 'Plans, trials and platform revenue',
          body:
              'Subscriptions arrive in Phase F, gated on the Play Console setup (plan D1).',
        ),
      ),
    ],
  );
}

/// Phase A (A1): shown when the review route is opened without the
/// picker's draft (for example a deep link). There is nothing to review
/// without a package, dates, and totals, so the screen says so and sends
/// the customer back to browsing shops instead of showing a fake summary.
class _CustomerNoDraftScreen extends StatelessWidget {
  const _CustomerNoDraftScreen({required this.onBrowseShops});

  final VoidCallback onBrowseShops;

  @override
  Widget build(BuildContext context) {
    // Phase F: the no-draft screen is user-facing copy, not a debug
    // message — it renders through AppLocalizations.
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 52,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noDraftTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noDraftMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onBrowseShops,
                  child: Text(l10n.noDraftBrowse),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

