import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/network/firestore_service.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/services/owner_onboarding_submission_service.dart';

/// Phase B (B4): the upload must go through the real client code
/// path — the old fake-URL-on-failure is gone. The test binding
/// answers every real HTTP request with 400, so a fake client that
/// answers 200 with a stored filename is injected instead.
class _FakeCPanelHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonEncode({'filename': 'shops/test_upload.jpg'});
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
    SharedPreferences.setMockInitialValues({});
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
    );
    sl.registerLazySingleton<AuthRemoteDataSource>(() => authDataSource);
  });

  tearDown(() async {
    await sl.reset();
  });

  test('Owner Onboarding: uploads photos to cPanel, stores protected HMAC links in Firestore, and sets pending verification', () async {
    // 1. Establish owner session
    await authDataSource.setLoggedIn(true);
    await authDataSource.saveProfileInfo(fullName: 'Kashif Mehmood', phone: '+923001234567');
    await authDataSource.assignPermanentRole(role: 'owner', fullName: 'Kashif Mehmood', phone: '+923001234567');

    final mockAccounts = [
      {
        'type': 'bank',
        'bank_name': 'Meezan Bank',
        'iban': 'PK36MEZN0001234567890123',
        'title': 'Kashif Rent a Car',
      },
      {
        'type': 'jazzcash',
        'account': '03001234567',
        'title': 'Kashif Mehmood',
      }
    ];

    // 2. Mock image files. The logo/header files exist in the tree
    // (0-byte PNGs); the CNIC/selfie mocks do not, so write real
    // temp files — the upload path checks exists() before sending,
    // and a missing file uploads nothing.
    final logoXFile = XFile('assets/images/white_sedan_hero.png');
    final headerXFile = XFile('assets/images/rentalhub_splash_logo.png');
    final tempDir = await Directory.systemTemp.createTemp();
    Future<XFile> tempImage(String name) async {
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(
          [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      return XFile(file.path);
    }

    final cnicFrontXFile = await tempImage('mock_cnic_front.jpg');
    final cnicBackXFile = await tempImage('mock_cnic_back.jpg');
    final selfieXFile = await tempImage('mock_selfie.jpg');

    // 3. Submit Showroom Profile
    final createdShop = await OwnerOnboardingSubmissionService.submitShowroomProfile(
      shopName: 'Kashif Rent a Car',
      ownerName: 'Kashif Mehmood',
      cnic: '35201-1234567-1',
      whatsapp: '03001234567',
      phone: '04235761234',
      openingHours: '9:00 AM - 11:00 PM',
      shopPin: const ll.LatLng(31.5204, 74.3587),
      address: 'Main Boulevard, Gulberg III, Lahore',
      city: 'Lahore',
      bankAccounts: mockAccounts,
      shopLogoFile: logoXFile,
      shopHeaderFile: headerXFile,
      fleetPhoto1File: logoXFile,
      fleetPhoto2File: null,
      fleetPhoto3File: null,
      cnicFrontFile: cnicFrontXFile,
      cnicBackFile: cnicBackXFile,
      ntnFile: null,
      selfieFile: selfieXFile,
    );

    // 4. Verify Shop Model properties
    expect(createdShop.shopName, 'Kashif Rent a Car');
    expect(createdShop.ownerName, 'Kashif Mehmood');
    expect(createdShop.isVerified, isFalse, reason: 'New showrooms must await Super Admin verification');
    expect(createdShop.verificationStatus, 'pending');

    // 5. Verify all stored picture links are cPanel protected signed URLs
    expect(createdShop.logoUrl, isNotNull);
    expect(createdShop.logoUrl, contains('auth='));
    expect(createdShop.logoUrl, contains('media.php?key='));

    expect(createdShop.headerUrl, isNotNull);
    expect(createdShop.headerUrl, contains('auth='));

    expect(createdShop.fleetPhotos.length, 1);
    expect(createdShop.fleetPhotos.first, contains('auth='));

    expect(createdShop.kycDocuments['cnic_front'], contains('auth='));
    expect(createdShop.kycDocuments['cnic_back'], contains('auth='));
    expect(createdShop.kycDocuments['selfie'], contains('auth='));

    // 6. Verify Shop document in Firestore
    final retrievedShop = await firestoreService.getShop(createdShop.shopId);
    expect(retrievedShop, isNotNull);
    expect(retrievedShop!.shopId, createdShop.shopId);
    expect(retrievedShop.shopName, 'Kashif Rent a Car');
    expect(retrievedShop.isVerified, isFalse);
    expect(retrievedShop.verificationStatus, 'pending');
    expect(retrievedShop.bankAccounts.length, 2);
    expect(retrievedShop.logoUrl, createdShop.logoUrl);
    expect(retrievedShop.headerUrl, createdShop.headerUrl);

    // 7. Verify Owner user is linked in Firestore
    final ownerUser = await firestoreService.getUser(createdShop.ownerId);
    expect(ownerUser, isNotNull);
    expect(ownerUser!.role, 'owner');
    expect(ownerUser.isOnboardingCompleted, isTrue);

    // 8. Verify local session state marked onboarding complete
    expect(authDataSource.isOnboardingCompleted, isTrue);
  });
}
