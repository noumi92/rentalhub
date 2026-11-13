import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/network/firestore_service.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';

/// Phase B (B4): the upload must go through the real client code
/// path — the old fake-URL-on-failure is gone. The test binding
/// answers every real HTTP request with 400, so a fake client that
/// answers 200 with a stored filename is injected instead.
class _FakeCPanelHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonEncode({'filename': 'profile/test_avatar.png'});
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FirestoreService firestoreService;
  late CPanelStorageClient cpanelClient;
  late AuthRemoteDataSource authDataSource;

  setUp(() async {
    await sl.reset();
    // Audit SH-C1: saveProfileInfo fails closed with no signed-in user
    // and no cached uid. The test simulates a signed-in user through
    // the cached-uid path the data source explicitly supports — the uid
    // is a test key in mock prefs, not a fallback in production code.
    SharedPreferences.setMockInitialValues(
        {'rentalhub_user_uid': 'usr_pk_001'});
    prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => prefs);

    firestoreService = FirestoreService();
    sl.registerLazySingleton<FirestoreService>(() => firestoreService);

    cpanelClient = CPanelStorageClient(
      apiSecretKey: 'RENTALHUB_HMAC_SECURE_STORAGE_SECRET_2026',
      httpClient: _FakeCPanelHttpClient(),
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

    // The mock file on disk does not exist in the local tree, so
    // write a real temp image: the upload path checks exists()
    // before sending, and a missing file uploads nothing.
    final tempDir = await Directory.systemTemp.createTemp();
    final mockImageFile = File('${tempDir.path}/mock_avatar.png');
    await mockImageFile.writeAsBytes(
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

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
    // Audit SH-M5: the stored score is only the offline fallback for
    // the live computation — a verified new customer is 3.5, never
    // 5.0 (the top of the scale before the customer has done anything).
    expect(user.trustScore, 3.5, reason: 'New users must have baseline 3.5 trust score, not fake 4.9 or perfect 5.0');
    expect(user.isVerified, isFalse, reason: 'New users must be unverified until NADRA/document verification');
  });
}

