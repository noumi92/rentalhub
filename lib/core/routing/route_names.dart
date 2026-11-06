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
  static const String ownerAddVehicle = '/owner/fleet/add';
  static const String ownerRates = '/owner/rates';
  static const String ownerRatesVehicle = '/owner/rates/:vehicleId';
  static const String ownerFixedRoutes = '/owner/fixed-routes';
  static const String ownerCalendar = '/owner/calendar/:vehicleId';
  static const String ownerRequests = '/owner/requests';
  static const String ownerRequestsDetail = '/owner/requests/:id';
  static const String ownerManualBooking = '/owner/manual-booking';
  static const String ownerPaymentProof = '/owner/payment/:id';
  static const String ownerHandover = '/owner/handover/:id';
  static const String ownerQrScan = '/owner/scan';
  static const String ownerReturn = '/owner/return/:id';
  static const String ownerContract = '/owner/contract/:id';
  static const String ownerRateCustomer = '/owner/rate-customer/:id';
  static const String ownerCustomerScan = '/owner/customers/scan';
  static const String ownerCustomers = '/owner/customers';
  static const String ownerBlacklist = '/owner/blacklist';
  static const String ownerSubscription = '/owner/subscription';
  static const String ownerWhatsappLogs = '/owner/whatsapp';
  static const String ownerNotifications = '/owner/notifications';
  static const String ownerSettings = '/owner/settings';
  static const String ownerFinance = '/owner/finance';
  static const String ownerDues = '/owner/finance/dues';
  static const String ownerCashClosing = '/owner/finance/closing';
  static const String ownerCarPnL = '/owner/finance/car';

  // Super Admin Routes (Web)
  static const String adminDashboard = '/admin/dashboard';
  static const String adminShops = '/admin/shops';
  static const String adminBlacklist = '/admin/blacklist';
  static const String adminSubscriptions = '/admin/subscriptions';
}

