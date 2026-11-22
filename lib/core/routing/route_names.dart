class RouteNames {
  // Root & Auth
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String onboardingRole = '/onboarding/role';
  static const String onboardingProfile = '/onboarding/profile';

  // Customer Routes — Phase A (A1): the real views, no mock flow view.
  static const String customerLocationPrompt = '/customer/location-prompt';
  static const String customerHome = '/customer/home';
  static const String customerHomeMap = '/customer/home/map';
  // Customer rework (tabs: Home, Shops, Bookings, Wallet, Profile):
  // the Shops tab root — the map/list discovery screen (Worker B).
  static const String customerShops = '/customer/shops';
  // Customer rework (07:42 PKT clarification): the Shops tab is the
  // LISTING by default; the full-screen Nearby showrooms map is a
  // sub-screen of the Shops branch (back returns to the listing).
  static const String customerShopsMap = '/customer/shops/map';
  static const String customerShopDetail = '/customer/shop/:shopId';
  static const String customerShopCars = '/customer/shop/:shopId/cars';
  static const String customerVehicleDetail = '/customer/vehicle/:id';
  static const String customerPackagePicker = '/customer/package/:vehicleId';
  static const String customerReviewBooking = '/customer/review/:id';
  static const String customerBookingSuccess = '/customer/success/:id';
  static const String customerBookingApproved = '/customer/approved/:id';
  static const String customerPaymentProof = '/customer/payment/:id';
  static const String customerPaymentProofUpload =
      '/customer/payment-proof/:id';
  static const String customerPickupPass = '/customer/pass/:id';
  static const String customerActiveTrip = '/customer/active/:id';
  static const String customerRateTrip = '/customer/rate/:id';
  static const String customerCancelBooking = '/customer/cancel/:id';
  static const String customerKyc = '/customer/kyc';
  static const String customerBookings = '/customer/bookings';
  static const String customerBookingDetail = '/customer/bookings/:id';
  static const String customerWallet = '/customer/wallet';
  static const String customerSupport = '/customer/support';
  static const String customerSos = '/customer/sos';
  static const String customerProfile = '/customer/profile';
  static const String customerSettings = '/customer/settings';
  static const String customerDisputes = '/customer/disputes';
  static const String customerReputation = '/customer/reputation';
  // Admin final pass (2026-11-10): the announcement detail screen —
  // the landing route for tapped admin announcement pushes.
  static const String customerAnnouncement = '/customer/announcement/:id';
  static const String customerSavedShops = '/customer/saved-shops';
  static const String customerNotifications = '/customer/notifications';

  // Owner Routes
  static const String ownerOnboarding = '/owner/onboarding';
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerFleet = '/owner/fleet';
  static const String ownerVehicleDetail = '/owner/vehicles/:id';
  static const String ownerEditVehicle = '/owner/vehicles/:id/edit';
  static const String ownerVehiclePublished =
      '/owner/fleet/published/:vehicleId';
  static const String ownerShareWithCustomers =
      '/owner/fleet/share/:vehicleId';
  static const String ownerFareTable = '/owner/fares/:vehicleId';
  static const String ownerPriceEstimate = '/owner/estimate/:vehicleId';
  static const String ownerFleetCalendar = '/owner/fleet/calendar';
  static const String ownerAddVehicle = '/owner/fleet/add';
  static const String ownerRates = '/owner/rates';
  static const String ownerRatesVehicle = '/owner/rates/:vehicleId';
  static const String ownerOutCityRules = '/owner/out-city-rules/:vehicleId';
  static const String ownerFixedRoutes = '/owner/fixed-routes';
  static const String ownerCalendar = '/owner/calendar/:vehicleId';
  static const String ownerRequests = '/owner/requests';
  static const String ownerRequestsDetail = '/owner/requests/:id';
  static const String ownerManualBooking = '/owner/manual-booking';
  static const String ownerManualBookingConfirm =
      '/owner/manual-booking/confirm';
  static const String ownerManualBookingReceipt =
      '/owner/manual-booking/receipt';
  static const String ownerBookingConfirmed = '/owner/booking-confirmed/:id';
  static const String ownerPaymentProof = '/owner/payment/:id';
  static const String ownerHandover = '/owner/handover/:id';
  // Item 10 (O46–O48): the agreement wizard (preview → terms →
  // share); `?step=0|1|2` picks the starting step, default 0.
  static const String ownerAgreementWizard = '/owner/agreement/:id';
  static const String ownerRentalStarted = '/owner/rental-started/:id';
  static const String ownerRecordDamage = '/owner/record-damage/:id';
  static const String ownerRecordExtraCharges =
      '/owner/record-extra-charges/:id';
  static const String ownerQrScan = '/owner/scan';
  static const String ownerReturn = '/owner/return/:id';
  static const String ownerReturnLanding = '/owner/return-landing/:id';
  static const String ownerContract = '/owner/contract/:id';
  static const String ownerRateCustomer = '/owner/rate-customer/:id';
  static const String ownerCustomerScan = '/owner/customers/scan';
  // OW-m22: the scan view pushed this path as a string literal.
  static const String ownerCnicReview = '/owner/customers/cnic-review';
  static const String ownerAddCustomer = '/owner/customers/add';
  static const String ownerCustomers = '/owner/customers';
  // Audit impl finish (worker A): customer detail is LAST in the
  // Customers branch so the static routes above match first.
  static const String ownerCustomerDetail = '/owner/customers/:id';
  // Walk-in CRM: edit a walk-in customer in the wizard (walk-in
  // only — the route refuses online records). 4 segments, so it
  // cannot collide with the 3-segment detail route above.
  static const String ownerCustomerEdit = '/owner/customers/:id/edit';
  // Customer Security wallet (Worker C): the shop-managed Security
  // view for one walk-in customer. 4 segments, like the edit route.
  static const String ownerCustomerSecurityWallet =
      '/owner/customers/:id/security-wallet';
  static const String ownerCustomerAdded = '/owner/customers/added/:id';
  static const String ownerBlacklist = '/owner/blacklist';
  static const String ownerSubscription = '/owner/subscription';
  static const String ownerSubscriptionPlan = '/owner/subscription/plan';
  static const String ownerSubscriptionPlayPurchase =
      '/owner/subscription/play-purchase';
  static const String ownerSubscriptionActive = '/owner/subscription/active';
  static const String ownerSubscriptionMy = '/owner/subscription/my';
  static const String ownerWhatsappLogs = '/owner/whatsapp';
  static const String ownerWhatsappCredits = '/owner/whatsapp/credits';
  static const String ownerWhatsappBuyCredits = '/owner/whatsapp/credits/buy';
  static const String ownerWhatsappCreditsAdded =
      '/owner/whatsapp/credits/added';
  static const String ownerWhatsappHistory = '/owner/whatsapp/history';
  static const String ownerWhatsappTemplate = '/owner/whatsapp/template';
  static const String ownerSignedOut = '/signed-out';
  static const String ownerNotifications = '/owner/notifications';
  static const String ownerDisputes = '/owner/disputes';
  static const String ownerSettings = '/owner/settings';
  static const String ownerFinance = '/owner/finance';
  static const String ownerReports = '/owner/finance/reports';
  static const String ownerCustomerStatement =
      '/owner/finance/statement/:customerId';
  static const String ownerFinanceSettings = '/owner/finance/settings';
  static const String ownerBookingSettings = '/owner/settings/booking';
  static const String ownerFinanceCategories = '/owner/finance/categories';
  static const String ownerDues = '/owner/finance/dues';
  static const String ownerCashClosing = '/owner/finance/closing';
  static const String ownerCarPnL = '/owner/finance/car';
  static const String ownerResetOptions = '/owner/settings/reset';
  static const String ownerStaffRoles = '/owner/settings/staff';
  static const String ownerShopSettings = '/owner/settings/shop';

  // Sync details (top-level, reachable from Settings and the failed
  // sync banner) — Phone-test #4.
  static const String syncDetails = '/sync-details';

  // Audit impl finish (worker C): legal texts, top-level like
  // syncDetails — no shell, no tab bar.
  static const String legalTermsOfService = '/terms';
  static const String legalPrivacyPolicy = '/privacy';

  // Super Admin Routes (Web)
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminTeam = '/admin/team';
  // F-M5: the invite accept screen — a super admin grants the role
  // from a shared invite link.
  static const String adminInviteAccept = '/admin/accept-invite';
  static const String adminApprovals = '/admin/approvals';
  // Item 6 — customer KYC review: the queue of `kyc_documents`
  // submissions waiting for a decision, and one submission's detail.
  static const String adminKycReview = '/admin/kyc-review';
  static const String adminKycReviewDetail = '/admin/kyc-review/:customerId';
  static const String adminCars = '/admin/cars';
  static const String adminShopDetail = '/admin/shops/:shopId';
  static const String adminCustomers = '/admin/customers';
  static const String adminCustomerDetail = '/admin/customers/:customerId';
  static const String adminBookings = '/admin/bookings';
  static const String adminBookingDetail = '/admin/bookings/:bookingId';
  static const String adminDisputes = '/admin/disputes';
  static const String adminReviews = '/admin/reviews';
  static const String adminTickets = '/admin/tickets';
  static const String adminSettings = '/admin/settings';
  static const String adminApkDownload = '/admin/apk-download';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminReports = '/admin/reports';
  static const String adminActivity = '/admin/activity';
  static const String adminShops = '/admin/shops';
  static const String adminBlacklist = '/admin/blacklist';
  static const String adminSubscriptions = '/admin/subscriptions';
}

