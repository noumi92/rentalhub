class RouteNames {
  // Root & Auth
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String onboardingRole = '/onboarding/role';
  static const String onboardingProfile = '/onboarding/profile';

  // Customer Routes
  static const String customerLocationPrompt = '/customer/location-prompt';
  static const String customerHome = '/customer/home';
  static const String customerHomeMap = '/customer/home/map';
  static const String customerVehicleDetail = '/customer/vehicle/:id';
  static const String customerReviewBooking = '/customer/review/:id';
  static const String customerPaymentProof = '/customer/payment/:id';
  static const String customerPickupPass = '/customer/pass/:id';
  static const String customerActiveTrip = '/customer/active/:id';
  static const String customerRateTrip = '/customer/rate/:id';
  static const String customerKyc = '/customer/kyc';

  // Owner Routes
  static const String ownerOnboarding = '/owner/onboarding';
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerFleet = '/owner/fleet';
  static const String ownerRates = '/owner/rates';
  static const String ownerRequests = '/owner/requests';
  static const String ownerHandover = '/owner/handover/:id';
  static const String ownerReturn = '/owner/return/:id';
  static const String ownerBlacklist = '/owner/blacklist';

  // Super Admin Routes (Web)
  static const String adminDashboard = '/admin/dashboard';
  static const String adminShops = '/admin/shops';
  static const String adminBlacklist = '/admin/blacklist';
  static const String adminSubscriptions = '/admin/subscriptions';
}

