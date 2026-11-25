import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/customer/domain/repositories/customer_repository.dart';
import 'package:rentalhub/features/customer/domain/usecases/save_customer_usecase.dart';
import 'package:rentalhub/features/customer/presentation/profile_hub_loader.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_edit_profile_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_profile_view.dart';
import 'package:rentalhub/features/trust/data/datasources/kyc_remote_data_source.dart';
import 'package:rentalhub/features/trust/domain/entities/kyc_document_entity.dart';
import 'package:rentalhub/features/trust/presentation/views/widgets/kyc_status_style.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Profile hub (2026-11-25): the KYC re-submit safety net, the
// edit-profile save path, and the hub deep link.

class _FakeStorageClient extends CPanelStorageClient {
  _FakeStorageClient() : super(apiSecretKey: 'test');

  @override
  Future<String> uploadFile({
    required File file,
    required String userUid,
    required String folder,
    Duration timeout = const Duration(seconds: 60),
  }) async =>
      '$folder/${file.path.split('/').last}';
}

Future<File> _tempFile(String name) async {
  final file = File('${Directory.systemTemp.path}/profile_hub_$name');
  await file.writeAsString('fake-image-bytes');
  return file;
}

Future<void> _seedVerifiedKyc(FakeFirebaseFirestore fake) async {
  await fake.collection('kyc_documents').doc('user-1').set({
    'userUid': 'user-1',
    'cnicNumber': '35202-1234567-1',
    'cnicFrontKey': 'kyc/old-front',
    'cnicBackKey': 'kyc/old-back',
    'licenseKey': 'kyc/old-lic',
    'licenseBackKey': 'kyc/old-lic-back',
    'licenseNumber': 'LHR-1234567',
    'licenseExpiry': '01.01.2030',
    'status': 'verified',
  });
}

KycRemoteDataSource _kycDataSource(FakeFirebaseFirestore fake) =>
    KycRemoteDataSource(
      storageClient: _FakeStorageClient(),
      firestore: fake,
    );

void main() {
  group('KycStatusStyle — one mapping for banner, Home card, hub', () {
    testWidgets('labels, colours and icons agree per status',
        (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(KycStatusStyle.label(l10n, 'verified'), 'Verified');
      expect(KycStatusStyle.label(l10n, 'rejected'),
          'Rejected — please resubmit');
      expect(KycStatusStyle.label(l10n, 'submitted'),
          'Submitted — pending verification');
      // 'resubmitted' reads as a pending submission, never verified.
      expect(KycStatusStyle.label(l10n, 'resubmitted'),
          'Submitted — pending verification');
      expect(KycStatusStyle.icon('verified'), Icons.verified_rounded);
      expect(KycStatusStyle.icon('resubmitted'),
          Icons.hourglass_top_rounded);
    });
  });

  group('KycRemoteDataSource — re-submit safety', () {
    test('verified re-submit becomes resubmitted and keeps stored keys',
        () async {
      final fake = FakeFirebaseFirestore();
      await _seedVerifiedKyc(fake);
      final ds = _kycDataSource(fake);

      final result = await ds.uploadCnicAndLicense(
        userUid: 'user-1',
        cnicNumber: '35202-1234567-1',
        previousStatus: 'verified',
      );

      expect(result.status, 'resubmitted');
      expect(result.cnicFrontKey, 'kyc/old-front');
      expect(result.cnicBackKey, 'kyc/old-back');
      expect(result.licenseKey, 'kyc/old-lic');
      expect(result.licenseBackKey, 'kyc/old-lic-back');
      expect(result.licenseNumber, 'LHR-1234567');
      expect(result.licenseExpiry, '01.01.2030');
      final stored = await ds.getKyc('user-1');
      expect(stored?.status, 'resubmitted');
      expect(stored?.licenseKey, 'kyc/old-lic');
    });

    test('verified re-submit with a new front photo replaces only that key',
        () async {
      final fake = FakeFirebaseFirestore();
      await _seedVerifiedKyc(fake);
      final ds = _kycDataSource(fake);
      final front = await _tempFile('front.jpg');

      final result = await ds.uploadCnicAndLicense(
        userUid: 'user-1',
        cnicNumber: '35202-1234567-1',
        cnicFront: front,
        previousStatus: 'verified',
      );

      expect(result.status, 'resubmitted');
      expect(result.cnicFrontKey, 'kyc/profile_hub_front.jpg');
      expect(result.cnicBackKey, 'kyc/old-back');
      expect(result.licenseKey, 'kyc/old-lic');
    });

    test('first submission is submitted and stores the uploaded keys',
        () async {
      final fake = FakeFirebaseFirestore();
      final ds = _kycDataSource(fake);
      final front = await _tempFile('first-front.jpg');
      final back = await _tempFile('first-back.jpg');

      final result = await ds.uploadCnicAndLicense(
        userUid: 'user-1',
        cnicNumber: '35202-1234567-1',
        cnicFront: front,
        cnicBack: back,
      );

      expect(result.status, 'submitted');
      expect(result.cnicFrontKey, 'kyc/profile_hub_first-front.jpg');
      expect(result.cnicBackKey, 'kyc/profile_hub_first-back.jpg');
    });

    test('flagForReReview demotes verified to resubmitted, leaves others',
        () async {
      final fake = FakeFirebaseFirestore();
      await _seedVerifiedKyc(fake);
      final ds = _kycDataSource(fake);

      await ds.flagForReReview('user-1');
      expect((await ds.getKyc('user-1'))?.status, 'resubmitted');
      // A second flag is a no-op: resubmitted is already pending.
      await ds.flagForReReview('user-1');
      expect((await ds.getKyc('user-1'))?.status, 'resubmitted');
    });

    test('syncCnicNumber keeps both CNIC sources in step', () async {
      final fake = FakeFirebaseFirestore();
      await _seedVerifiedKyc(fake);
      final ds = _kycDataSource(fake);

      await ds.syncCnicNumber('user-1', '35202-7654321-7');
      final stored = await ds.getKyc('user-1');
      expect(stored?.cnicNumber, '35202-7654321-7');
      expect(stored?.status, 'verified');
      expect(stored?.licenseKey, 'kyc/old-lic');
      // No KYC record: no write, no crash.
      await ds.syncCnicNumber('nobody', '35202-1111111-1');
    });
  });

  group('CustomerEditProfileView — save path', () {
    testWidgets(
        'CNIC edit saves through SaveCustomerUseCase, syncs the KYC '
        'record and flags re-review', (tester) async {
      final fake = FakeFirebaseFirestore();
      await _seedVerifiedKyc(fake);
      final saved = <CustomerEntity>[];
      final repo = _FakeCustomerRepository(onSave: saved.add);
      final kycDs = _kycDataSource(fake);
      final data = ProfileHubData(
        name: 'Ali Raza',
        email: 'ali@example.com',
        phone: '03001234567',
        cnic: '35202-1234567-1',
        photoUrl: null,
        dateOfBirth: '01.01.1990',
        fatherName: 'Ahmed Raza',
        address: 'Lahore',
        trustScore: 4.2,
        kycStatus: 'verified',
        isBlacklisted: false,
        loading: false,
        loadFailed: false,
        kyc: const KycDocumentEntity(
          userUid: 'user-1',
          cnicNumber: '35202-1234567-1',
          cnicFrontKey: 'kyc/old-front',
          cnicBackKey: 'kyc/old-back',
          licenseKey: 'kyc/old-lic',
          status: 'verified',
        ),
        rejectionReason: null,
        ownerReviews: const [],
        customer: CustomerEntity(
          customerId: 'user-1',
          shopId: '',
          name: 'Ali Raza',
          phone: '03001234567',
          cnic: '35202-1234567-1',
          source: 'online',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerEditProfileView(
            initialData: data,
            saveUseCase: SaveCustomerUseCase(repo),
            kycDataSource: kycDs,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Change only the CNIC.
      final cnicField = find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.labelText == 'CNIC (optional)');
      await tester.enterText(cnicField, '35202-7654321-7');
      await tester.pumpAndSettle();
      // The re-review warning appears for a verified record.
      expect(
        find.text(
            'Changing your CNIC will send your KYC back for review.'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Save Profile'));
      await tester.tap(find.text('Save Profile'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(saved.single.name, 'Ali Raza');
      expect(saved.single.phone, '03001234567');
      expect(saved.single.cnic, '35202-7654321-7');
      // DOB / father's name / address round-trip through the save.
      expect(saved.single.dateOfBirth, '01.01.1990');
      expect(saved.single.fatherName, 'Ahmed Raza');
      expect(saved.single.address, 'Lahore');
      // Owner approval is untouched by a CNIC edit.
      expect(saved.single.approvalStatus, 'pending');
      // The KYC record now carries the new CNIC and is pending
      // re-review, with its stored keys intact.
      final stored = await kycDs.getKyc('user-1');
      expect(stored?.cnicNumber, '35202-7654321-7');
      expect(stored?.status, 'resubmitted');
      expect(stored?.licenseKey, 'kyc/old-lic');
    });

    testWidgets('unchanged CNIC on a verified record does not flag review',
        (tester) async {
      final fake = FakeFirebaseFirestore();
      await _seedVerifiedKyc(fake);
      final saved = <CustomerEntity>[];
      final repo = _FakeCustomerRepository(onSave: saved.add);
      final kycDs = _kycDataSource(fake);
      final data = ProfileHubData(
        name: 'Ali Raza',
        email: '',
        phone: '03001234567',
        cnic: '35202-1234567-1',
        photoUrl: null,
        dateOfBirth: null,
        fatherName: null,
        address: null,
        trustScore: null,
        kycStatus: 'verified',
        isBlacklisted: false,
        loading: false,
        loadFailed: false,
        kyc: const KycDocumentEntity(
          userUid: 'user-1',
          cnicNumber: '35202-1234567-1',
          cnicFrontKey: 'kyc/old-front',
          cnicBackKey: 'kyc/old-back',
          licenseKey: 'kyc/old-lic',
          status: 'verified',
        ),
        rejectionReason: null,
        ownerReviews: const [],
        customer: CustomerEntity(
          customerId: 'user-1',
          shopId: '',
          name: 'Ali Raza',
          phone: '03001234567',
          cnic: '35202-1234567-1',
          source: 'online',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerEditProfileView(
            initialData: data,
            saveUseCase: SaveCustomerUseCase(repo),
            kycDataSource: kycDs,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Profile'));
      await tester.tap(find.text('Save Profile'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect((await kycDs.getKyc('user-1'))?.status, 'verified');
    });
  });

  group('CustomerProfileView — hub deep link', () {
    testWidgets('/customer/kyc opens the hub on the KYC tab',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CustomerProfileView(initialTab: 1),
        ),
      );
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller?.index, 1);
      expect(find.text('KYC'), findsOneWidget);
      // 'Profile' renders twice by design: the app-bar title and
      // the first tab.
      expect(find.text('Profile'), findsNWidgets(2));
    });

    testWidgets('default hub opens on the Profile tab', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CustomerProfileView(),
        ),
      );
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller?.index, 0);
      // 'Guest' renders twice by design: the header name and the
      // identity card's name row.
      expect(find.text('Guest'), findsNWidgets(2));
    });
  });
}

class _FakeCustomerRepository implements CustomerRepository {
  final void Function(CustomerEntity customer) onSave;

  _FakeCustomerRepository({required this.onSave});

  @override
  Future<void> upsertCustomer(CustomerEntity customer) async =>
      onSave(customer);

  @override
  Future<List<CustomerEntity>> getShopCustomers(String shopId) async =>
      const [];

  @override
  Future<CustomerEntity?> getCustomerByCnic(
          String shopId, String cnic) async =>
      null;

  @override
  Future<void> updateCustomerStatus({
    required String customerId,
    required String shopId,
    required String status,
  }) async {}

  @override
  Future<void> archiveCustomer({
    required String customerId,
    required String shopId,
  }) async {}
}
