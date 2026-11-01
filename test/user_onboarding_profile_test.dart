import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/network/firestore_service.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FirestoreService firestoreService;
  late CPanelStorageClient cpanelClient;
  late AuthRemoteDataSource authDataSource;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => prefs);

    firestoreService = FirestoreService();
    sl.registerLazySingleton<FirestoreService>(() => firestoreService);

    cpanelClient = CPanelStorageClient(
      apiSecretKey: 'RENTALHUB_HMAC_SECURE_STORAGE_SECRET_2026',
    );
    sl.registerLazySingleton<CPanelStorageClient>(() => cpanelClient);

    authDataSource = AuthRemoteDataSource(
      prefs: prefs,
      firestoreService: firestoreService,
      storageClient: cpanelClient,
    );
    sl.registerLazySingleton<AuthRemoteDataSource>(() => authDataSource);
  });

  tearDown(() async {
    await sl.reset();
  });

  test('User Onboarding: saves profile info without fake data and uploads profile photo to cPanel', () async {
    await authDataSource.setLoggedIn(true);

    // Provide a dummy profile image file
    final mockImageFile = File('test/mock_avatar.png');

    await authDataSource.saveProfileInfo(
      fullName: 'Daniyal Khan',
      phone: '03009988776',
      profilePhotoFile: mockImageFile,
    );

    expect(authDataSource.fullName, 'Daniyal Khan');
    expect(authDataSource.phoneNumber, '03009988776');
    expect(authDataSource.profilePhotoUrl, isNotNull);
    expect(authDataSource.profilePhotoUrl, contains('media.php?key='));
    expect(authDataSource.profilePhotoUrl, contains('auth='));

    // Verify Firestore user record has NO fake data
    final user = await firestoreService.getUser('usr_pk_001');
    expect(user, isNotNull);
    expect(user!.fullName, 'Daniyal Khan');
    expect(user.phoneNumber, '03009988776');
    expect(user.profilePhotoUrl, authDataSource.profilePhotoUrl);

    // Strict assertions against hardcoded fake data
    expect(user.totalTrips, 0, reason: 'New users must have 0 total trips, not fake 7');
    expect(user.trustScore, 5.0, reason: 'New users must have baseline 5.0 trust score, not fake 4.9');
    expect(user.isVerified, isFalse, reason: 'New users must be unverified until NADRA/document verification');
  });
}

