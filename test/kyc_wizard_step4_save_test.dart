import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/customer/domain/usecases/save_customer_usecase.dart';
import 'package:rentalhub/features/customer/utils/save_walk_in_customer.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_customer_saver.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_media_upload_service.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step4_guarantor.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Add Customer wizard (O15) — step 4 guarantor UI plus the save path
// through KycCustomerSaver: canned uploads, blacklist refusal, and a
// failed required upload aborting the save.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Step 4 — guarantor UI', () {
    testWidgets(
        'search filters, picking shows relation + on-file box, '
        'completeness box appears when the draft is complete',
        (tester) async {
      final ds = di.sl<CustomerRemoteDataSource>();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-kyc-g1',
        shopId: 'shop-kyc-w4',
        name: 'Guarantor One',
        phone: '0300-1111111',
        cnic: '35201-1111111-1',
        source: 'walk_in',
        createdAt: DateTime(2026, 11, 9),
        signatureUrl: 'https://cdn.example/kyc/sig.png',
      ));
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-kyc-g2',
        shopId: 'shop-kyc-w4',
        name: 'Other Person',
        phone: '0300-2222222',
        cnic: '35201-2222222-2',
        source: 'walk_in',
        createdAt: DateTime(2026, 11, 9),
      ));

      final draft = _fullDraft(cnic: '35201-7777777-7');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Step4Guarantor(
                draft: draft,
                onChanged: () {},
                shopId: 'shop-kyc-w4',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The draft is complete, so the blue box shows before any pick.
      expect(find.text('KYC complete: CNIC, Photo, Thumb, License, Signature'),
          findsOneWidget);
      expect(find.text('Guarantor One'), findsOneWidget);
      expect(find.text('Other Person'), findsOneWidget);
      // No guarantor picked yet: no green on-file box, no relation
      // value shown.
      expect(
          find.text(
              'Signature & thumbprint on file — fetched automatically'),
          findsNothing);
      expect(find.text('Friend'), findsNothing);

      // Searching filters the list.
      await tester.enterText(
          find.widgetWithText(TextField, 'Search existing customers'),
          'Guarantor');
      await tester.pumpAndSettle();
      expect(find.text('Guarantor One'), findsOneWidget);
      expect(find.text('Other Person'), findsNothing);
      await tester.enterText(
          find.widgetWithText(TextField, 'Search existing customers'), '');
      await tester.pumpAndSettle();
      expect(find.text('Other Person'), findsOneWidget);

      // Picking the guarantor shows the relation dropdown (the
      // draft's relation, 'Family' here) and — he has a signature
      // on file — the green box.
      await tester.tap(find.text('Guarantor One'));
      await tester.pumpAndSettle();
      expect(draft.guarantorCustomerId, 'cust-kyc-g1');
      expect(find.text('Family'), findsOneWidget);
      expect(
          find.text(
              'Signature & thumbprint on file — fetched automatically'),
          findsOneWidget);
      expect(find.text('Guarantor is optional — you can save without one'),
          findsOneWidget);

      // Tapping the selected guarantor again clears the pick.
      await tester.tap(find.text('Guarantor One'));
      await tester.pumpAndSettle();
      expect(draft.guarantorCustomerId, isNull);
      expect(
          find.text(
              'Signature & thumbprint on file — fetched automatically'),
          findsNothing);
    });

    testWidgets('empty shop shows the honest empty state',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Step4Guarantor(
                draft: KycDraft(),
                onChanged: () {},
                shopId: 'shop-kyc-w4-empty',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No saved customers yet.'), findsOneWidget);
    });
  });

  group('Save path — KycCustomerSaver', () {
    test('full draft saves with URLs, guarantor and identity fields',
        () async {
      final ds = di.sl<CustomerRemoteDataSource>();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-g1',
        shopId: 'shop-1',
        name: 'Guarantor One',
        phone: '0300-1111111',
        cnic: '35201-1111111-1',
        source: 'walk_in',
        createdAt: DateTime(2026, 11, 9),
      ));
      final saver = _saver(
        uploader: _CannedUploader(),
        blacklist: _FakeBlacklist(false),
      );
      final draft = _fullDraft(
        cnic: '35201-4444444-4',
        guarantorId: 'cust-g1',
        relation: 'Family',
      );
      final result = await saver.save(shopId: 'shop-1', draft: draft);
      expect(result.queuedPhotos, 0);
      expect(result.skippedExtraDocs, 0);

      final saved = await ds.getCustomerByCnic('shop-1', '35201-4444444-4');
      expect(saved, isNotNull);
      expect(saved!.profilePhotoUrl, 'https://cdn.example/kyc/face.jpg');
      expect(saved.thumbprintUrl, 'https://cdn.example/kyc/thumb.jpg');
      expect(saved.cnicFrontUrl, 'https://cdn.example/kyc/cnic-front.jpg');
      expect(saved.licenseNumber, 'LHR-1234567');
      expect(saved.licenseExpiry, '01.01.2030');
      expect(saved.signatureUrl, 'https://cdn.example/kyc/signature.png');
      expect(saved.guarantorCustomerId, 'cust-g1');
      expect(saved.guarantorRelation, 'Family');
      expect(saved.fatherName, 'Test Father');
      expect(saved.address, 'House 12, Street 4, Gulberg III, Lahore');
    });

    test('blacklisted CNIC is refused and nothing is saved', () async {
      final saver = _saver(
        uploader: _CannedUploader(),
        blacklist: _FakeBlacklist(true),
      );
      final draft = _fullDraft(cnic: '35201-5555555-5');
      await expectLater(
        () => saver.save(shopId: 'shop-1', draft: draft),
        throwsA(isA<BlacklistedCustomerException>()),
      );
      final saved = await di.sl<CustomerRemoteDataSource>()
          .getCustomerByCnic('shop-1', '35201-5555555-5');
      expect(saved, isNull);
    });

    test('failed required upload aborts the save', () async {
      final saver = _saver(
        uploader: _CannedUploader(failedFields: ['profilePhotoUrl']),
        blacklist: _FakeBlacklist(false),
      );
      final draft = _fullDraft(cnic: '35201-6666666-6');
      await expectLater(
        () => saver.save(shopId: 'shop-1', draft: draft),
        throwsA(isA<StateError>()),
      );
      final saved = await di.sl<CustomerRemoteDataSource>()
          .getCustomerByCnic('shop-1', '35201-6666666-6');
      expect(saved, isNull);
    });
  });
}

/// Uploader fake: returns canned signed URLs for every field the
/// wizard captures, never touching the network or the disk. The
/// [failedFields] variant reports those fields as failed.
class _CannedUploader extends KycMediaUploadService {
  final List<String> failedFields;

  _CannedUploader({this.failedFields = const []});

  @override
  Future<KycUploadResult> uploadAll({
    required String shopId,
    required String customerId,
    required KycDraft draft,
  }) async {
    final result = KycUploadResult();
    result.urls.addAll({
      'profilePhotoUrl': 'https://cdn.example/kyc/face.jpg',
      'thumbprintUrl': 'https://cdn.example/kyc/thumb.jpg',
      'cnicFrontUrl': 'https://cdn.example/kyc/cnic-front.jpg',
      'cnicBackUrl': 'https://cdn.example/kyc/cnic-back.jpg',
      'licenseFrontUrl': 'https://cdn.example/kyc/license-front.jpg',
      'licenseBackUrl': 'https://cdn.example/kyc/license-back.jpg',
      'utilityBillUrl': 'https://cdn.example/kyc/utility-bill.jpg',
      'signatureUrl': 'https://cdn.example/kyc/signature.png',
    });
    result.failedFields.addAll(failedFields);
    return result;
  }
}

class _FakeBlacklist extends BlacklistRemoteDataSource {
  final bool blocked;

  _FakeBlacklist(this.blocked);

  @override
  Future<bool> isCnicBlacklisted(String cnicNumber) async => blocked;
}

KycCustomerSaver _saver({
  required KycMediaUploadService uploader,
  required BlacklistRemoteDataSource blacklist,
}) =>
    KycCustomerSaver(
      saveUseCase: di.sl<SaveCustomerUseCase>(),
      blacklist: blacklist,
      uploader: uploader,
    );

KycDraft _fullDraft({
  required String cnic,
  String? guarantorId,
  String relation = 'Family',
}) {
  final draft = KycDraft();
  draft.name = 'Test Customer';
  draft.fatherName = 'Test Father';
  draft.cnic = cnic;
  draft.dateOfBirth = '15.03.1990';
  draft.cnicExpiry = '01.01.2030';
  draft.address = 'House 12, Street 4, Gulberg III, Lahore';
  draft.phone = '0300-4444444';
  draft.licenseNumber = 'LHR-1234567';
  draft.licenseExpiry = '01.01.2030';
  draft.facePhoto = XFile('test/assets/mock_selfie.jpg');
  draft.thumbprintPhoto = XFile('test/assets/mock_selfie.jpg');
  draft.cnicFrontPhoto = XFile('test/assets/mock_selfie.jpg');
  draft.cnicBackPhoto = XFile('test/assets/mock_selfie.jpg');
  draft.licenseFrontPhoto = XFile('test/assets/mock_selfie.jpg');
  draft.licenseBackPhoto = XFile('test/assets/mock_selfie.jpg');
  draft.utilityBillPhoto = XFile('test/assets/mock_selfie.jpg');
  draft.signaturePng = Uint8List.fromList([1, 2, 3]);
  draft.termsAgreed = true;
  draft.guarantorCustomerId = guarantorId;
  draft.guarantorRelation = relation;
  return draft;
}
