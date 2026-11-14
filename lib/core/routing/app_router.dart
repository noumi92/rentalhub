import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_shell.dart';
import '../widgets/app_shell_nav.dart';
import '../../l10n/app_localizations.dart';
import '../platform/app_platform.dart';
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
import '../../features/discovery/presentation/views/customer_shops_view.dart';
import '../../features/discovery/presentation/views/customer_home_view.dart';
import '../../features/discovery/presentation/views/customer_home_map_view.dart';
import '../../features/discovery/presentation/views/shop_cars_view.dart';
import '../../features/discovery/presentation/views/shop_detail_view.dart';
import '../../features/discovery/presentation/views/vehicle_detail_view.dart';
import '../../features/trust/presentation/views/customer_documents_view.dart';
import '../../features/owner/presentation/views/owner_add_customer_wizard.dart';
import '../../features/owner/presentation/views/owner_cnic_review_view.dart';
import '../../features/trust/utils/cnic_text_parser.dart';
import '../../features/owner/presentation/views/owner_add_vehicle_view.dart';
import '../../features/owner/presentation/views/owner_booking_requests_view.dart';
import '../../features/owner/presentation/views/owner_contract_view.dart';
import '../../features/owner/presentation/views/owner_customer_detail_view.dart';
import '../../features/owner/presentation/views/owner_customer_added_view.dart';
import '../../features/owner/presentation/views/owner_return_landing_view.dart';
import '../../features/owner/presentation/views/owner_share_with_customers_view.dart';
import '../../features/auth/presentation/views/legal_text_view.dart';
import '../../features/customer/domain/entities/customer_entity.dart';
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
import '../../features/owner/presentation/views/owner_manual_booking_confirm_view.dart';
import '../../features/fleet/domain/entities/vehicle_entity.dart';
import '../../features/fleet/domain/entities/fixed_route_entity.dart';
import '../../features/owner/presentation/widgets/guarantor_picker.dart';
import '../../features/owner/presentation/views/owner_onboarding_view.dart';
import '../../features/owner/presentation/views/owner_rate_matrix_view.dart';
import '../../features/owner/presentation/views/owner_out_city_rules_view.dart';
import '../../features/owner/presentation/views/owner_edit_vehicle_view.dart';
import '../../features/owner/presentation/views/owner_return_settlement_view.dart';
import '../../features/owner/presentation/views/owner_car_pnl_view.dart';
import '../../features/owner/presentation/views/owner_cash_closing_view.dart';
import '../../features/owner/presentation/views/owner_dues_view.dart';
import '../../features/owner/presentation/views/owner_finance_view.dart';
import '../../features/owner/presentation/views/owner_disputes_view.dart';
import '../../features/owner/presentation/views/owner_notifications_view.dart';
import '../../features/owner/presentation/views/owner_settings_view.dart';
import '../../features/owner/presentation/views/owner_subscription_view.dart';
import '../../features/owner/presentation/views/owner_subscription_plan_detail_view.dart';
import '../../features/owner/presentation/views/owner_subscription_play_purchase_view.dart';
import '../../features/owner/presentation/views/owner_subscription_active_view.dart';
import '../../features/owner/presentation/views/owner_subscription_my_view.dart';
import '../../features/owner/presentation/views/owner_whatsapp_credits_view.dart';
import '../../features/owner/presentation/views/owner_whatsapp_buy_credits_view.dart';
import '../../features/owner/presentation/views/owner_whatsapp_credits_added_view.dart';
import '../../features/owner/presentation/views/owner_whatsapp_history_view.dart';
import '../../features/owner/presentation/views/owner_whatsapp_template_preview_view.dart';
import '../../features/owner/presentation/views/owner_vehicle_calendar_view.dart';
import '../../features/owner/presentation/views/owner_vehicle_detail_view.dart';
import '../../features/owner/presentation/views/owner_vehicle_published_view.dart';
import '../../features/owner/presentation/views/owner_fare_table_view.dart';
import '../../features/owner/presentation/views/owner_price_estimate_view.dart';
import '../../features/owner/presentation/views/owner_shop_settings_view.dart';
import '../../features/owner/presentation/views/owner_fleet_calendar_view.dart';
import '../../features/owner/presentation/views/owner_booking_confirmed_view.dart';
import '../../features/owner/presentation/views/owner_agreement_signed_view.dart';
import '../../features/owner/presentation/views/owner_rental_started_view.dart';
import '../../features/owner/presentation/views/owner_record_damage_view.dart';
import '../../features/owner/presentation/views/owner_record_extra_charges_view.dart';
import '../../features/owner/presentation/views/owner_reports_view.dart';
import '../../features/owner/presentation/views/owner_customer_statement_view.dart';
import '../../features/owner/presentation/views/owner_finance_settings_view.dart';
import '../../features/owner/presentation/views/owner_finance_categories_view.dart';
import '../../features/owner/presentation/views/owner_reset_options_view.dart';
import '../../features/owner/presentation/views/owner_staff_roles_view.dart';
import '../../features/owner/presentation/views/owner_signed_out_view.dart';
import '../../features/owner/presentation/views/owner_fleet_view.dart';
import '../../features/owner/presentation/widgets/owner_route_loaders.dart';
import '../../features/owner/presentation/widgets/owner_requests_badge.dart';
import '../../features/customer/presentation/widgets/customer_bookings_badge.dart';
import '../../features/customer/presentation/widgets/customer_support_badge.dart';
import '../../features/settings/presentation/views/sync_details_view.dart';
import '../../features/admin/presentation/views/admin_activity_log_view.dart';
import '../../features/admin/presentation/views/admin_apk_download_view.dart';
import '../../features/admin/presentation/views/admin_cars_view.dart';
import '../../features/admin/presentation/views/admin_customer_detail_view.dart';
import '../../features/admin/presentation/views/admin_customers_view.dart';
import '../../features/admin/presentation/views/admin_kyc_review_detail_view.dart';
import '../../features/admin/presentation/views/admin_kyc_review_view.dart';
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
import '../../features/admin/presentation/views/admin_invite_accept_view.dart';
import '../../features/admin/presentation/views/admin_coming_soon_view.dart';
import '../../features/admin/presentation/views/admin_dashboard_view.dart';
import '../../features/admin/presentation/views/admin_login_view.dart';
import '../../features/admin/presentation/views/admin_team_view.dart';
import '../../features/notifications/presentation/views/announcement_detail_view.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNav');


  /// Customer rework (tabs: Home, Shops, Bookings, Wallet, Profile).
  /// Support is no longer a tab: it lives as a top-level sub-screen
  /// (see below the customer shell) reached from Profile and the home
  /// bell, and its unread indicator moved to the Profile Support row
  /// (`CustomerSupportBadge` there). CU-M11: the tabs themselves now
  /// carry badges too — Bookings counts bookings needing action
  /// (approved-awaiting-payment, proof-rejected) and Profile surfaces
  /// the support-reply badge — the same `Badge` pattern as the owner
  /// Requests tab. The other tabs have plain icons.
  /// Phase F: each tab carries an l10nKey — the label renders in the
  /// current locale (the plain `label` stays the English fallback).
  static final customerTabs = <ShellNavItem>[
    const ShellNavItem(
        icon: Icon(Icons.home_rounded), label: 'Home', l10nKey: 'navHome'),
    const ShellNavItem(
        icon: Icon(Icons.store_rounded),
        label: 'Shops',
        l10nKey: 'navShops'),
    ShellNavItem(
        icon: CustomerBookingsBadge(
            icon: const Icon(Icons.receipt_long_rounded)),
        label: 'Bookings',
        l10nKey: 'navBookings'),
    const ShellNavItem(
        icon: Icon(Icons.account_balance_wallet_rounded),
        label: 'Wallet',
        l10nKey: 'navWallet'),
    ShellNavItem(
        icon: CustomerSupportBadge(
            icon: const Icon(Icons.person_rounded)),
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

  /// Web is the admin panel: it starts on the admin login with no
  /// in-app splash (a signed-in admin is auto-continued to the
  /// dashboard by AdminLoginView). Mobile keeps the splash.
  /// A getter, not a const, so tests can flip
  /// AppPlatform.isWebOverride — the GoRouter below is a static
  /// final built once.
  static String get initialLocation =>
      AppPlatform.isWeb ? RouteNames.adminLogin : RouteNames.splash;

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
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
                  builder: (context, vehicle, shopName, shopPhone,
                          shopOwnerId) =>
                      VehicleDetailView(
                    vehicle: vehicle,
                    shopName: shopName,
                    shopPhone: shopPhone,
                    shopOwnerId: shopOwnerId,
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
                  builder: (context, vehicle, shopName, shopPhone, _) =>
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
          // Customer rework: Shops tab (index 1) — the map/list
          // discovery screen (Worker B: CustomerShopsView). Its own
          // branch so tab switches keep its scroll/filter state.
          StatefulShellBranch(
            routes: [
              // Shops: customerShops
              GoRoute(
                path: RouteNames.customerShops,
                builder: (context, state) => const CustomerShopsView(),
              ),
              // Shops: customerShopsMap — the full-screen Nearby
              // showrooms map (CustomerHomeMapView, reused as-is;
              // Worker B owns its fix-ups). A branch-internal
              // sub-screen, like /customer/home/map in the Home
              // branch: NOT a tab root, so the tab bar hides and
              // back returns to the Shops listing.
              GoRoute(
                path: RouteNames.customerShopsMap,
                builder: (context, state) => const CustomerHomeMapView(),
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
              // Profile: customerProfile
              GoRoute(
                path: RouteNames.customerProfile,
                builder: (context, state) => CustomerProfileView(
                  onOpenDocuments: () => context.push(RouteNames.customerKyc),
                  onOpenSavedShops: () => context.push(RouteNames.customerSavedShops),
                  onOpenSettings: () => context.push(RouteNames.customerSettings),
                  onOpenReputation: () => context.push(RouteNames.customerReputation),
                  // Customer rework: Support moved into Profile — the
                  // row pushes the top-level support sub-screen.
                  onOpenSupport: () => context.push(RouteNames.customerSupport),
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

      // Customer rework: Support is NO LONGER a shell branch — it is
      // a top-level sub-screen (same pattern as syncDetails / the
      // legal texts): no tab bar, back arrow returns to wherever it
      // was opened from. Path and name are UNCHANGED
      // (RouteNames.customerSupport = '/customer/support'), so the
      // home bell and every existing push keep working — the bell now
      // pushes (was go) so the back arrow exists. SOS and Disputes
      // move with it: they are pushed from Support, from the home
      // quick actions, and from booking details, all of which push
      // onto the root navigator from inside a shell branch.
      GoRoute(
        path: RouteNames.customerSupport,
        builder: (context, state) => CustomerSupportView(
          onFileDispute: () => context.push(RouteNames.customerDisputes),
          onOpenSos: () => context.push(RouteNames.customerSos),
        ),
      ),
      GoRoute(
        path: RouteNames.customerSos,
        builder: (context, state) =>
            CustomerSosView(onBack: () => context.pop()),
      ),
      GoRoute(
        path: RouteNames.customerDisputes,
        builder: (context, state) => CustomerDisputeView(
          initialBookingId: state.uri.queryParameters['bookingId'],
          onDisputeSubmitted: () => context.pop(),
          onBack: () => context.pop(),
        ),
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
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['vehicleId']!;
                  return MaterialPage(
                    // Phone bug: go_router keys a page by its route
                    // PATTERN ('/owner/rates/:vehicleId'), so two rates
                    // pages — the same vehicle pushed twice, or rates
                    // for two vehicles — share one key and trip the
                    // branch Navigator's duplicate-key assertion
                    // (debug red screen on "Manage rates"). Key by
                    // the concrete vehicle instead.
                    key: ValueKey('owner-rates-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) => OwnerRateMatrixView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerOutCityRules (09b/010b simplification,
              // worker B) — car-level shared out-of-city rules.
              GoRoute(
                path: RouteNames.ownerOutCityRules,
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['vehicleId']!;
                  return MaterialPage(
                    // Same pattern-key hazard as ownerRatesVehicle.
                    key: ValueKey('owner-out-city-rules-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) => OwnerOutCityRulesView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerEditVehicle (09b/010b simplification,
              // worker B route wiring; the view is worker C's).
              GoRoute(
                path: RouteNames.ownerEditVehicle,
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['id']!;
                  return MaterialPage(
                    // Same pattern-key hazard as ownerRatesVehicle.
                    key: ValueKey('owner-edit-vehicle-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) => OwnerEditVehicleView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerCalendar
              GoRoute(
                path: RouteNames.ownerCalendar,
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['vehicleId']!;
                  return MaterialPage(
                    // Same pattern-key hazard as ownerRatesVehicle.
                    key: ValueKey('owner-calendar-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) =>
                          OwnerVehicleCalendarView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerFixedRoutes
              GoRoute(
                path: RouteNames.ownerFixedRoutes,
                builder: (context, state) => OwnerFixedRoutesView(
                  shopId: currentShopId(),
                  onBack: () => context.pop(),
                ),
              ),
              // Fleet: ownerVehicleDetail (audit impl, worker D)
              GoRoute(
                path: RouteNames.ownerVehicleDetail,
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['id']!;
                  return MaterialPage(
                    // Same pattern-key hazard as ownerRatesVehicle.
                    key: ValueKey('owner-vehicle-detail-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) => OwnerVehicleDetailView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerVehiclePublished (audit impl, worker D)
              GoRoute(
                path: RouteNames.ownerVehiclePublished,
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['vehicleId']!;
                  return MaterialPage(
                    // Same pattern-key hazard as ownerRatesVehicle.
                    key: ValueKey('owner-vehicle-published-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) =>
                          OwnerVehiclePublishedView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerShareWithCustomers (audit impl finish,
              // worker C) — VehicleRouteLoader pattern, per-vehicle
              // MaterialPage key, like ownerVehiclePublished.
              GoRoute(
                path: RouteNames.ownerShareWithCustomers,
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['vehicleId']!;
                  return MaterialPage(
                    // Same pattern-key hazard as ownerRatesVehicle.
                    key: ValueKey('owner-share-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) =>
                          OwnerShareWithCustomersView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerFareTable (audit impl, worker D)
              GoRoute(
                path: RouteNames.ownerFareTable,
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['vehicleId']!;
                  return MaterialPage(
                    // Same pattern-key hazard as ownerRatesVehicle.
                    key: ValueKey('owner-fare-table-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) => OwnerFareTableView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerPriceEstimate (audit impl, worker D)
              GoRoute(
                path: RouteNames.ownerPriceEstimate,
                pageBuilder: (context, state) {
                  final vehicleId = state.pathParameters['vehicleId']!;
                  return MaterialPage(
                    // Same pattern-key hazard as ownerRatesVehicle.
                    key: ValueKey('owner-price-estimate-$vehicleId'),
                    child: VehicleRouteLoader(
                      vehicleId: vehicleId,
                      shopId: currentShopId(),
                      builder: (context, vehicle) => OwnerPriceEstimateView(
                        vehicle: vehicle,
                        onBack: () => context.pop(),
                      ),
                    ),
                  );
                },
              ),
              // Fleet: ownerFleetCalendar (audit impl, worker D)
              GoRoute(
                path: RouteNames.ownerFleetCalendar,
                builder: (context, state) => OwnerFleetCalendarView(
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
              // Audit impl (worker A): vehicle/dates/trip type arrive
              // as query params from the request-detail "Convert to
              // manual entry" action.
              GoRoute(
                path: RouteNames.ownerManualBooking,
                builder: (context, state) => OwnerManualBookingView(
                  prefilledCnic: state.uri.queryParameters['cnic'],
                  prefilledName: state.uri.queryParameters['name'],
                  prefilledPhone: state.uri.queryParameters['phone'],
                  prefilledVehicleId:
                      state.uri.queryParameters['vehicle'],
                  prefilledPickupTime: DateTime.tryParse(
                      state.uri.queryParameters['pickup'] ?? ''),
                  prefilledReturnTime: DateTime.tryParse(
                      state.uri.queryParameters['return'] ?? ''),
                  prefilledTripType:
                      state.uri.queryParameters['tripType'],
                ),
              ),
              // Requests: ownerManualBookingConfirm (RQ-F8, 2026-11-13
              // — was pushed with Navigator from the manual form, no
              // route/deep link). The form passes its validated draft
              // via extra, same pattern as the CNIC-review route;
              // without extra the manual form is shown instead of
              // crashing on a deep link.
              GoRoute(
                path: RouteNames.ownerManualBookingConfirm,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final vehicle = extra?['vehicle'] as VehicleEntity?;
                  final package =
                      extra?['package'] as VehiclePackageEntity?;
                  final pickup = extra?['pickupTime'] as DateTime?;
                  final returnTime = extra?['returnTime'] as DateTime?;
                  final customerName = extra?['customerName'] as String?;
                  final customerPhone = extra?['customerPhone'] as String?;
                  final customerCnic = extra?['customerCnic'] as String?;
                  if (vehicle == null ||
                      package == null ||
                      pickup == null ||
                      returnTime == null ||
                      customerName == null ||
                      customerPhone == null ||
                      customerCnic == null) {
                    return const OwnerManualBookingView();
                  }
                  return OwnerManualBookingConfirmView(
                    customerName: customerName,
                    customerPhone: customerPhone,
                    customerCnic: customerCnic,
                    guarantor:
                        extra?['guarantor'] as GuarantorSelection?,
                    vehicle: vehicle,
                    package: package,
                    isWithDriver: extra?['isWithDriver'] as bool? ?? false,
                    isOutOfCity: extra?['isOutOfCity'] as bool? ?? false,
                    pickupTime: pickup,
                    returnTime: returnTime,
                    fixedRoute: extra?['fixedRoute'] as FixedRouteEntity?,
                  );
                },
              ),
              // Requests: ownerBookingConfirmed (audit impl, worker A)
              GoRoute(
                path: RouteNames.ownerBookingConfirmed,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => OwnerBookingConfirmedView(
                    booking: booking,
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Requests: ownerAgreementSigned (audit impl, worker B)
              GoRoute(
                path: RouteNames.ownerAgreementSigned,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => OwnerAgreementSignedView(
                    booking: booking,
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Requests: ownerRentalStarted (audit impl, worker B)
              GoRoute(
                path: RouteNames.ownerRentalStarted,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => OwnerRentalStartedView(
                    booking: booking,
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Requests: ownerRecordDamage (audit impl, worker B)
              GoRoute(
                path: RouteNames.ownerRecordDamage,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => OwnerRecordDamageView(
                    booking: booking,
                    onBack: () => context.pop(),
                  ),
                ),
              ),
              // Requests: ownerRecordExtraCharges (audit impl, worker B)
              GoRoute(
                path: RouteNames.ownerRecordExtraCharges,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) =>
                      OwnerRecordExtraChargesView(
                    booking: booking,
                    onBack: () => context.pop(),
                  ),
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
              // Requests: ownerReturnLanding (audit impl finish,
              // worker B) — the contract view's "Proceed to Return"
              // lands here; Start goes to ownerReturn.
              GoRoute(
                path: RouteNames.ownerReturnLanding,
                builder: (context, state) => BookingRouteLoader(
                  bookingId: state.pathParameters['id']!,
                  builder: (context, booking) => OwnerReturnLandingView(
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
                builder: (context, state) => OwnerAddCustomerWizard(
                  prefilledCnic: state.uri.queryParameters['cnic'],
                ),
              ),
              // Customers: CNIC review (audit §20/C11 — was pushed
              // with Navigator from the scan view, no route/deep link).
              // The scan view passes its OCR result + front-photo path
              // + onSaved callback via extra; without extra the scan
              // view is shown instead of crashing on a deep link.
              GoRoute(
                path: RouteNames.ownerCnicReview,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final result = extra?['result'] as CnicScanResult?;
                  if (result == null) return const OwnerCustomerScanView();
                  return OwnerCnicReviewView(
                    initial: result,
                    frontImagePath: extra?['frontImagePath'] as String?,
                    onSaved: extra?['onSaved'] as ValueChanged<String>?,
                  );
                },
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
              // Customers: ownerCustomerAdded (audit impl finish,
              // worker A) — O13 success screen after the wizard saves.
              // 4 segments, so it cannot collide with the 3-segment
              // ownerCustomerDetail below.
              GoRoute(
                path: RouteNames.ownerCustomerAdded,
                builder: (context, state) => OwnerCustomerAddedView(
                  customerId: state.pathParameters['id']!,
                  customer: state.extra as CustomerEntity?,
                ),
              ),
              // Customers: ownerCustomerDetail (audit impl finish,
              // worker A) — the 1 missing screen (#35). Declared LAST
              // in this branch, after the static /add, /scan and
              // /cnic-review routes, so they keep matching first.
              // Sub-screen — never in tabRootPaths.
              GoRoute(
                path: RouteNames.ownerCustomerDetail,
                builder: (context, state) => OwnerCustomerDetailView(
                  customerId: state.pathParameters['id']!,
                  shopId: currentShopId(),
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
              // Settings: ownerWhatsappLogs — RQ-F16 (2026-11-13):
              // `/owner/whatsapp` now serves the history view, which
              // reads the real `whatsapp_dispatch_logs` collection.
              // The legacy logs view (honest empty state, no
              // collection) is unrouted; delete it via the GitHub
              // web UI with `WhatsAppLogTile` (see the rulebook
              // v1.0.5 entry). `/owner/whatsapp/history` serves the
              // same view.
              GoRoute(
                path: RouteNames.ownerWhatsappLogs,
                builder: (context, state) => const OwnerWhatsappHistoryView(),
              ),
              // Settings: ownerDisputes
              GoRoute(
                path: RouteNames.ownerDisputes,
                builder: (context, state) => OwnerDisputesView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerReports (audit impl, worker C)
              GoRoute(
                path: RouteNames.ownerReports,
                builder: (context, state) => OwnerReportsView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerCustomerStatement (audit impl, worker C)
              GoRoute(
                path: RouteNames.ownerCustomerStatement,
                builder: (context, state) => OwnerCustomerStatementView(
                  shopId: currentShopId(),
                  customerId: state.pathParameters['customerId']!,
                ),
              ),
              // Settings: ownerFinanceSettings (audit impl, worker C)
              GoRoute(
                path: RouteNames.ownerFinanceSettings,
                builder: (context, state) => OwnerFinanceSettingsView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerFinanceCategories (audit impl, worker C)
              GoRoute(
                path: RouteNames.ownerFinanceCategories,
                builder: (context, state) => OwnerFinanceCategoriesView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerResetOptions (audit impl, worker C)
              GoRoute(
                path: RouteNames.ownerResetOptions,
                builder: (context, state) => OwnerResetOptionsView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerStaffRoles (audit impl, worker C)
              GoRoute(
                path: RouteNames.ownerStaffRoles,
                builder: (context, state) => OwnerStaffRolesView(
                  shopId: currentShopId(),
                ),
              ),
              // Settings: ownerShopSettings (audit impl, worker D)
              GoRoute(
                path: RouteNames.ownerShopSettings,
                builder: (context, state) => const OwnerShopSettingsView(),
              ),
              // Settings: ownerSubscriptionPlan (audit impl, worker E).
              // state.extra is the plan id: 'free' | 'pro' | 'business'.
              GoRoute(
                path: RouteNames.ownerSubscriptionPlan,
                builder: (context, state) {
                  final planId = state.extra as String? ?? 'free';
                  return OwnerSubscriptionPlanDetailView(planId: planId);
                },
              ),
              // Settings: ownerSubscriptionPlayPurchase (audit impl,
              // worker E). state.extra is {'planId': String,
              // 'yearly': bool}; no in-app navigation reaches it yet
              // (D1-gated), the route exists so the sheet is built and
              // reachable once Play billing lands.
              GoRoute(
                path: RouteNames.ownerSubscriptionPlayPurchase,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return OwnerSubscriptionPlayPurchaseView(
                    planId: extra?['planId'] as String? ?? 'free',
                    yearly: extra?['yearly'] as bool? ?? false,
                  );
                },
              ),
              // Settings: ownerSubscriptionActive (audit impl, worker E)
              GoRoute(
                path: RouteNames.ownerSubscriptionActive,
                builder: (context, state) =>
                    const OwnerSubscriptionActiveView(),
              ),
              // Settings: ownerSubscriptionMy (audit impl, worker E)
              GoRoute(
                path: RouteNames.ownerSubscriptionMy,
                builder: (context, state) =>
                    const OwnerSubscriptionMyView(),
              ),
              // Settings: ownerWhatsappCredits (audit impl, worker E)
              GoRoute(
                path: RouteNames.ownerWhatsappCredits,
                builder: (context, state) => OwnerWhatsappCreditsView(
                  onBack: () => context.pop(),
                ),
              ),
              // Settings: ownerWhatsappBuyCredits (audit impl, worker E)
              GoRoute(
                path: RouteNames.ownerWhatsappBuyCredits,
                builder: (context, state) =>
                    const OwnerWhatsappBuyCreditsView(),
              ),
              // Settings: ownerWhatsappCreditsAdded (audit impl,
              // worker E). state.extra is {'requestSubmitted': bool,
              // 'pack': int?, 'price': int?, 'previousBalance': int?,
              // 'newBalance': int?}.
              GoRoute(
                path: RouteNames.ownerWhatsappCreditsAdded,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return OwnerWhatsappCreditsAddedView(
                    requestSubmitted:
                        extra?['requestSubmitted'] as bool? ?? false,
                    pack: (extra?['pack'] as num?)?.toInt(),
                    price: (extra?['price'] as num?)?.toInt(),
                    previousBalance:
                        (extra?['previousBalance'] as num?)?.toInt(),
                    newBalance: (extra?['newBalance'] as num?)?.toInt(),
                  );
                },
              ),
              // Settings: ownerWhatsappHistory (audit impl, worker E)
              GoRoute(
                path: RouteNames.ownerWhatsappHistory,
                builder: (context, state) =>
                    const OwnerWhatsappHistoryView(),
              ),
              // Settings: ownerWhatsappTemplate (audit impl, worker E)
              GoRoute(
                path: RouteNames.ownerWhatsappTemplate,
                builder: (context, state) =>
                    const OwnerWhatsappTemplatePreviewView(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: RouteNames.ownerOnboarding,
        builder: (context, state) => OwnerOnboardingView(
          // Audit impl (worker D): the fleet-add gate links to the
          // Application Status step (?step=status opens step 6).
          initialStep:
              state.uri.queryParameters['step'] == 'status' ? 6 : 1,
        ),
      ),
      GoRoute(
        // Phone-test #4: top-level (not inside a shell branch) so the
        // failed-sync banner and Settings can open it without a tab bar.
        path: RouteNames.syncDetails,
        builder: (context, state) => const SyncDetailsView(),
      ),
      GoRoute(
        // Audit impl (worker C, O49): top-level, like syncDetails —
        // the signed-out screen has no tab bar. Reached from the
        // Settings sign-out action after the confirm dialog.
        path: RouteNames.ownerSignedOut,
        builder: (context, state) => const OwnerSignedOutView(),
      ),
      GoRoute(
        // Audit impl finish (worker C): top-level, like syncDetails —
        // the legal texts have no shell and no tab bar. Reached from
        // the login footer.
        path: RouteNames.legalTermsOfService,
        builder: (context, state) => const LegalTextView(
          document: LegalDocument.terms,
        ),
      ),
      GoRoute(
        // Audit impl finish (worker C): top-level, like syncDetails.
        path: RouteNames.legalPrivacyPolicy,
        builder: (context, state) => const LegalTextView(
          document: LegalDocument.privacy,
        ),
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
      // Item 6 — customer KYC review queue + one submission's detail.
      GoRoute(
        path: RouteNames.adminKycReview,
        builder: (context, state) => const AdminKycReviewView(),
      ),
      GoRoute(
        path: RouteNames.adminKycReviewDetail,
        builder: (context, state) => AdminKycReviewDetailView(
          customerId: state.pathParameters['customerId'] ?? '',
        ),
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
        path: RouteNames.adminApkDownload,
        builder: (context, state) => const AdminApkDownloadView(),
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
      // F-M5: invite accept — a super admin grants the role from a
      // shared invite link (email + role as query parameters).
      GoRoute(
        path: RouteNames.adminInviteAccept,
        builder: (context, state) => AdminInviteAcceptView(
          email: state.uri.queryParameters['email'] ?? '',
          role: state.uri.queryParameters['role'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.adminActivity,
        builder: (context, state) => const AdminActivityLogView(),
      ),
      // Admin final pass (2026-11-10): the announcement detail
      // screen — the landing route for tapped admin announcement
      // pushes (see the AnnouncementPushHandler subscription in
      // main.dart). Top-level, not a shell branch: a push can arrive
      // on any tab, and the screen stands alone with its own bar.
      GoRoute(
        path: RouteNames.customerAnnouncement,
        builder: (context, state) => AnnouncementDetailView(
          announcementId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.adminSubscriptions,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return AdminComingSoonView(
            activeRoute: RouteNames.adminSubscriptions,
            title: l10n?.admin2_navSubscriptions ?? 'Subscriptions',
            subtitle: l10n?.admin2_subscriptionsSubtitle ??
                'Plans, trials and platform revenue',
            body: l10n?.admin2_subscriptionsBody ??
                'Subscriptions arrive in Phase F, gated on the Play Console setup (plan D1).',
          );
        },
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 52,
                  // Item 4: the old Colors.grey is ~2.9:1 on the light
                  // scaffold (below the 3:1 non-text minimum) — the
                  // theme variant is 4.76:1 in light, 6.99:1 in dark.
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.noDraftTitle ?? 'No booking in progress.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.noDraftMessage ??
                      'Pick a car and a package first — the review screen needs the booking details from there.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onBrowseShops,
                  child: Text(l10n?.noDraftBrowse ?? 'Browse shops'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

