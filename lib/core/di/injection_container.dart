import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';
import '../data/firestore_set_handler.dart';
import '../data/offline_sync_queue.dart';
import '../data/sync_engine.dart';
import '../data/sync_status_cubit.dart';
import '../data/upload_sync_handler.dart';
import '../network/connectivity_service.dart';
import '../settings/app_settings_cubit.dart';
import '../network/cpanel_storage_client.dart';
import '../network/firestore_service.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/assign_user_role_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/customer/data/datasources/customer_remote_data_source.dart';
import '../../features/customer/data/datasources/dispute_remote_data_source.dart';
import '../../features/admin/data/datasources/admin_remote_data_source.dart';
import '../../features/admin/data/datasources/admin_shops_data_source.dart';
import '../../features/admin/data/datasources/admin_people_data_source.dart';
import '../../features/admin/data/datasources/admin_platform_data_source.dart';
import '../../features/admin/data/datasources/admin_support_data_source.dart';
import '../../features/customer/data/datasources/review_remote_data_source.dart';
import '../../features/customer/data/repositories/customer_repository_impl.dart';
import '../../features/customer/domain/repositories/customer_repository.dart';
import '../../features/customer/domain/usecases/get_shop_customers_usecase.dart';
import '../../features/customer/domain/usecases/save_customer_usecase.dart';
import '../../features/trust/data/datasources/kyc_remote_data_source.dart';
import '../../features/trust/data/repositories/kyc_repository_impl.dart';
import '../../features/trust/domain/repositories/kyc_repository.dart';
import '../../features/trust/domain/usecases/upload_kyc_document_usecase.dart';
import '../../features/trust/presentation/cubit/kyc_cubit.dart';
import '../../features/discovery/data/datasources/discovery_remote_data_source.dart';
import '../../features/discovery/data/repositories/discovery_repository_impl.dart';
import '../../features/discovery/domain/repositories/discovery_repository.dart';
import '../../features/discovery/domain/usecases/get_nearby_shops_usecase.dart';
import '../../features/discovery/presentation/cubit/discovery_cubit.dart';
import '../../features/fleet/data/datasources/fixed_route_remote_data_source.dart';
import '../../features/fleet/data/datasources/fleet_remote_data_source.dart';
import '../../features/fleet/data/repositories/fixed_route_repository_impl.dart';
import '../../features/fleet/data/repositories/fleet_repository_impl.dart';
import '../../features/fleet/domain/repositories/fixed_route_repository.dart';
import '../../features/fleet/domain/repositories/fleet_repository.dart';
import '../../features/fleet/domain/usecases/add_vehicle_usecase.dart';
import '../../features/fleet/domain/usecases/delete_fixed_route_usecase.dart';
import '../../features/fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import '../../features/fleet/domain/usecases/get_shop_vehicles_usecase.dart';
import '../../features/fleet/domain/usecases/save_fixed_route_usecase.dart';
import '../../features/fleet/domain/usecases/update_vehicle_pricing_usecase.dart';
import '../../features/fleet/domain/usecases/update_vehicle_status_usecase.dart';
import '../../features/fleet/presentation/cubit/fleet_cubit.dart';
import '../../features/bookings/data/datasources/booking_remote_data_source.dart';
import '../../features/bookings/data/repositories/booking_repository_impl.dart';
import '../../features/bookings/domain/repositories/booking_repository.dart';
import '../../features/bookings/domain/usecases/create_booking_request_usecase.dart';
import '../../features/bookings/domain/usecases/update_booking_status_usecase.dart';
import '../../features/bookings/domain/usecases/get_customer_bookings_usecase.dart';
import '../../features/payments/domain/usecases/verify_payment_usecase.dart';
import '../../features/payments/presentation/cubit/payment_cubit.dart';
import '../../features/finance/data/datasources/cash_closing_data_source.dart';
import '../../features/finance/data/datasources/finance_account_data_source.dart';
import '../../features/finance/data/datasources/finance_transfer_data_source.dart';
import '../../features/finance/data/datasources/partner_share_data_source.dart';
import '../../features/finance/data/datasources/security_deposit_data_source.dart';
import '../../features/notifications/data/datasources/notification_data_source.dart';
import '../../features/handover/data/datasources/handover_local_data_source.dart';
import '../../features/handover/presentation/cubit/handover_cubit.dart';
import '../../features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../features/blacklist/presentation/cubit/blacklist_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  if (sl.isRegistered<CPanelStorageClient>()) return;

  // 1. External Singletons
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // 2. Network & Storage Clients
  sl.registerLazySingleton<CPanelStorageClient>(
    () => CPanelStorageClient(
      baseUrl: ApiEndpoints.cpanelBaseUrl,
      apiSecretKey: 'RENTALHUB_HMAC_SECURE_STORAGE_SECRET_2026',
      httpClient: sl<http.Client>(),
    ),
  );

  // 3. Cloud Firestore Service
  FirebaseFirestore? firestoreInstance;
  try {
    firestoreInstance = FirebaseFirestore.instance;
  } catch (e) {
    debugPrint('FirebaseFirestore instance registration notice: $e');
  }
  sl.registerLazySingleton<FirestoreService>(
    () => FirestoreService(firestore: firestoreInstance),
  );

  // Phase B (B2/B3): connectivity awareness + the shared offline
  // sync queue + its drain engine. Registered here so every data
  // source below can take the queue; the handlers are registered
  // at the end of this function, once the features exist.
  sl.registerLazySingleton<OfflineSyncQueue>(
    () => OfflineSyncQueue(prefs: sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );
  sl.registerLazySingleton<SyncEngine>(
    () => SyncEngine(queue: sl<OfflineSyncQueue>()),
  );
  sl.registerLazySingleton<UploadSyncHandler>(
    () => UploadSyncHandler(storageClient: sl<CPanelStorageClient>()),
  );
  sl.registerLazySingleton<FirestoreSetHandler>(
    () => FirestoreSetHandler(),
  );
  // Phase B (B5): the visible sync state (offline banner, pending
  // counts, per-item chips).
  sl.registerLazySingleton<SyncStatusCubit>(
    () => SyncStatusCubit(
      connectivity: sl<ConnectivityService>(),
      queue: sl<OfflineSyncQueue>(),
    ),
  );

  // 3.5 Firebase Auth
  fb.FirebaseAuth? firebaseAuthInstance;
  try {
    firebaseAuthInstance = fb.FirebaseAuth.instance;
  } catch (e) {
    debugPrint('FirebaseAuth instance registration notice: $e');
  }

  // 4. Auth Feature
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(
      prefs: sl<SharedPreferences>(),
      auth: firebaseAuthInstance,
      firestoreService: sl<FirestoreService>(),
      storageClient: sl<CPanelStorageClient>(),
      syncQueue: sl<OfflineSyncQueue>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => AssignUserRoleUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithEmailUseCase(sl<AuthRepository>()));
  sl.registerFactory(
    () => AuthCubit(
      assignRoleUseCase: sl<AssignUserRoleUseCase>(),
      signInWithGoogleUseCase: sl<SignInWithGoogleUseCase>(),
      signInWithEmailUseCase: sl<SignInWithEmailUseCase>(),
    ),
  );

  // Phase B (G3): app language + theme, one shared instance so
  // main.dart and the settings screen read the same state.
  sl.registerLazySingleton<AppSettingsCubit>(
    () => AppSettingsCubit(prefs: sl<SharedPreferences>()),
  );

  // 4. Trust / KYC Feature
  sl.registerLazySingleton<KycRemoteDataSource>(
    () => KycRemoteDataSource(
      storageClient: sl<CPanelStorageClient>(),
      syncQueue: sl<OfflineSyncQueue>(),
    ),
  );
  sl.registerLazySingleton<KycRepository>(
    () => KycRepositoryImpl(remoteDataSource: sl<KycRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => UploadKycDocumentUseCase(sl<KycRepository>()));
  sl.registerFactory(
    () => KycCubit(uploadKycUseCase: sl<UploadKycDocumentUseCase>()),
  );

  // 4b. Customers Feature (Phase B, C1)
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSource(syncQueue: sl<OfflineSyncQueue>()),
  );
  // G4: the customer's disputes (file + list), with an in-memory
  // fallback like the booking data source.
  sl.registerLazySingleton<DisputeRemoteDataSource>(
    () => DisputeRemoteDataSource(),
  );
  // Phase A (A1): the admin panel's data layer — Cloud Functions for
  // TOTP + roles, Firestore for invites and the team list.
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSource(),
  );
  // Phase B: the shops side of the admin panel (approvals, shops, cars).
  sl.registerLazySingleton<AdminShopsDataSource>(
    () => AdminShopsDataSource(),
  );
  // Phase C: customers, the blacklist and the trust score.
  sl.registerLazySingleton<AdminPeopleDataSource>(
    () => AdminPeopleDataSource(),
  );
  // Phase D: bookings, disputes, reviews.
  sl.registerLazySingleton<AdminPlatformDataSource>(
    () => AdminPlatformDataSource(),
  );
  // Phase E: support, settings, announcements, reports.
  sl.registerLazySingleton<AdminSupportDataSource>(
    () => AdminSupportDataSource(),
  );
  // H4: the real reviews store — one document per booking, rated
  // once by each side. No in-memory fallback: a rating that only
  // lives on the device would be a lie to the other side.
  sl.registerLazySingleton<ReviewRemoteDataSource>(
    () => ReviewRemoteDataSource(),
  );
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
        remoteDataSource: sl<CustomerRemoteDataSource>()),
  );
  sl.registerLazySingleton(
      () => GetShopCustomersUseCase(sl<CustomerRepository>()));
  sl.registerLazySingleton(
      () => SaveCustomerUseCase(sl<CustomerRepository>()));

  // 5. Discovery Feature
  sl.registerLazySingleton<DiscoveryRemoteDataSource>(
    () => DiscoveryRemoteDataSource(),
  );
  sl.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepositoryImpl(
        remoteDataSource: sl<DiscoveryRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetNearbyShopsUseCase(sl<DiscoveryRepository>()),
  );
  sl.registerFactory(
    () => DiscoveryCubit(getNearbyShopsUseCase: sl<GetNearbyShopsUseCase>()),
  );

  // 6. Fleet Feature
  sl.registerLazySingleton<FleetRemoteDataSource>(
    () => FleetRemoteDataSource(
      syncQueue: sl<OfflineSyncQueue>(),
    ),
  );
  sl.registerLazySingleton<FleetRepository>(
    () => FleetRepositoryImpl(remoteDataSource: sl<FleetRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => AddVehicleUseCase(sl<FleetRepository>()));
  sl.registerLazySingleton(
      () => GetShopVehiclesUseCase(sl<FleetRepository>()));
  sl.registerLazySingleton(
      () => UpdateVehicleStatusUseCase(sl<FleetRepository>()));
  sl.registerLazySingleton(
      () => UpdateVehiclePricingUseCase(sl<FleetRepository>()));
  sl.registerLazySingleton<FixedRouteRemoteDataSource>(
    () => FixedRouteRemoteDataSource(syncQueue: sl<OfflineSyncQueue>()),
  );
  sl.registerLazySingleton<FixedRouteRepository>(
    () => FixedRouteRepositoryImpl(
        remoteDataSource: sl<FixedRouteRemoteDataSource>()),
  );
  sl.registerLazySingleton(
      () => GetShopFixedRoutesUseCase(sl<FixedRouteRepository>()));
  sl.registerLazySingleton(
      () => SaveFixedRouteUseCase(sl<FixedRouteRepository>()));
  sl.registerLazySingleton(
      () => DeleteFixedRouteUseCase(sl<FixedRouteRepository>()));
  sl.registerFactory(
    () => FleetCubit(
      addVehicleUseCase: sl<AddVehicleUseCase>(),
      getShopVehiclesUseCase: sl<GetShopVehiclesUseCase>(),
      updateVehicleStatusUseCase: sl<UpdateVehicleStatusUseCase>(),
      updateVehiclePricingUseCase: sl<UpdateVehiclePricingUseCase>(),
    ),
  );

  // 7. Bookings & Payments Feature
  // Phase B (G2): owner notifications — written when booking and
  // payment events happen, read on the notifications screen.
  sl.registerLazySingleton<NotificationDataSource>(
    () => NotificationDataSource(),
  );
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSource(
        notifications: sl<NotificationDataSource>(),
        blacklist: sl<BlacklistRemoteDataSource>(),
        syncQueue: sl<OfflineSyncQueue>()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
        remoteDataSource: sl<BookingRemoteDataSource>()),
  );
  sl.registerLazySingleton(
      () => CreateBookingRequestUseCase(sl<BookingRepository>()));
  sl.registerLazySingleton(
      () => UpdateBookingStatusUseCase(sl<BookingRepository>()));
  sl.registerLazySingleton(
      () => GetCustomerBookingsUseCase(sl<BookingRepository>()));
  sl.registerLazySingleton(
      () => VerifyPaymentUseCase(sl<BookingRepository>()));
  sl.registerFactory(
    () => PaymentCubit(
      storageClient: sl<CPanelStorageClient>(),
      bookingRepository: sl<BookingRepository>(),
      syncQueue: sl<OfflineSyncQueue>(),
    ),
  );

  // 8. Offline Handover Feature (Phase 3)
  sl.registerLazySingleton<HandoverLocalDataSource>(
    () => HandoverLocalDataSource(prefs: sl<SharedPreferences>()),
  );
  // Phase B (F2): security deposits — collected at handover,
  // settled at return.
  sl.registerLazySingleton<SecurityDepositDataSource>(
    () => SecurityDepositDataSource(syncQueue: sl<OfflineSyncQueue>()),
  );
  // Phase B (H): finance — accounts, ledger, partners, cash closing.
  sl.registerLazySingleton<FinanceAccountDataSource>(
    () => FinanceAccountDataSource(syncQueue: sl<OfflineSyncQueue>()),
  );
  sl.registerLazySingleton<FinanceTransferDataSource>(
    () => FinanceTransferDataSource(
      syncQueue: sl<OfflineSyncQueue>(),
    ),
  );
  sl.registerLazySingleton<PartnerShareDataSource>(
    () => PartnerShareDataSource(syncQueue: sl<OfflineSyncQueue>()),
  );
  sl.registerLazySingleton<CashClosingDataSource>(
    () => CashClosingDataSource(syncQueue: sl<OfflineSyncQueue>()),
  );
  sl.registerFactory(
    () => HandoverCubit(
      localDataSource: sl<HandoverLocalDataSource>(),
      storageClient: sl<CPanelStorageClient>(),
      depositDataSource: sl<SecurityDepositDataSource>(),
    ),
  );

  // 9. Blacklist & Tribunal Feature (Phase 4)
  sl.registerLazySingleton<BlacklistRemoteDataSource>(
    () => BlacklistRemoteDataSource(),
  );
  sl.registerFactory(
    () => BlacklistCubit(dataSource: sl<BlacklistRemoteDataSource>()),
  );

  // Phase B (B2/B3): the sync engine's handlers, one per queue
  // kind. Registered last so every data source above exists.
  final syncEngine = sl<SyncEngine>();
  syncEngine.registerHandler('upload', sl<UploadSyncHandler>().call);
  syncEngine.registerHandler(
      'firestore_set', sl<FirestoreSetHandler>().call);
  syncEngine.registerHandler(
      'booking_create', sl<BookingRemoteDataSource>().syncQueuedCreate);
  syncEngine.registerHandler(
      'booking_update', sl<BookingRemoteDataSource>().syncQueuedUpdate);
  syncEngine.registerHandler(
      'handover', sl<HandoverCubit>().syncQueuedEntry);
}
