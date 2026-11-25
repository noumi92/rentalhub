import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/widgets/media_picker_helper.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_customer_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_qr_code_row.dart';
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/customer/domain/repositories/customer_repository.dart';
import 'package:rentalhub/features/customer/domain/usecases/save_customer_usecase.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_customer_saver.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_media_upload_service.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step1_cnic.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step3_docs.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_cnic_review_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_detail_view.dart';
import 'package:rentalhub/features/trust/data/models/customer_qr_code_model.dart';
import 'package:rentalhub/features/trust/data/services/cnic_ocr_service.dart';
import 'package:rentalhub/features/trust/data/services/customer_qr_code_service.dart';
import 'package:rentalhub/features/trust/data/services/document_qr_service.dart';
import 'package:rentalhub/features/trust/domain/entities/kyc_document_entity.dart';
import 'package:rentalhub/features/trust/domain/repositories/kyc_repository.dart';
import 'package:rentalhub/features/trust/domain/usecases/upload_kyc_document_usecase.dart';
import 'package:rentalhub/features/trust/presentation/cubit/kyc_cubit.dart';
import 'package:rentalhub/features/trust/presentation/views/widgets/kyc_submission_form.dart';
import 'package:rentalhub/features/trust/utils/cnic_text_parser.dart';
import 'package:rentalhub/features/trust/utils/license_document_parser.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helper.dart';

/// KYC camera + QR (Worker G, 2026-11-10):
/// - every CNIC/license capture opens the BACK camera, never the
///   gallery;
/// - CNIC front OCR auto-fills the CNIC number;
/// - the CNIC back QR holds a NUMBER stored as `qrCode` in the
///   restricted `customer_qr_codes/{customerId}` doc — never parsed
///   into name/CNIC fields, never rendered outside the admin panel,
///   and only for a super admin there;
/// - the driving license gets the same capture treatment with OCR
///   auto-fill of number/expiry.
/// Fake CNIC OCR: returns canned results instead of ML Kit.
class _FakeCnicOcrService extends CnicOcrService {
  final CnicScanResult frontResult;
  final CnicScanResult backResult;

  _FakeCnicOcrService({required this.frontResult, required this.backResult});

  @override
  Future<CnicScanResult> scanFront(File image) async => frontResult;

  @override
  Future<CnicScanResult> scanBack(File image) async => backResult;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockImagePickerPlatform mockPicker;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  setUp(() {
    mockPicker = MockImagePickerPlatform.setup();
    mockPicker.mockResult = XFile('test/assets/mock_cnic.jpg');
    // On-device ML Kit has no platform side in widget tests: an
    // unmocked channel call is forwarded to the real engine messenger
    // and never completes, so every OCR scan would hang behind its
    // spinner and pumpAndSettle would time out. Answer with an empty
    // recognition (no text found) so scans complete through the real
    // "unreadable" path instead of hanging.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('google_mlkit_text_recognizer'),
      (MethodCall call) async {
        if (call.method == 'vision#startTextRecognizer') {
          return <String, dynamic>{'text': '', 'blocks': <dynamic>[]};
        }
        return null;
      },
    );
  });

  tearDown(() {
    MockImagePickerPlatform.tearDown();
  });

  Future<void> pumpApp(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LicenseTextParser — license OCR text into fields', () {
    test('labelled number and expiry are read', () {
      final r = LicenseTextParser.parseLicenseText(
        'Driving Licence\nLicense No\nLHR-1234567\nDate of Expiry\n01.01.2030',
      );
      expect(r.licenseNumber, 'LHR-1234567');
      expect(r.dateOfExpiry, '01.01.2030');
      expect(r.hasAnything, isTrue);
    });

    test('unlabelled number shape and slash dates still parse', () {
      final r = LicenseTextParser.parseLicenseText(
        'LHR-15-123456\nValid Upto 01/01/2030',
      );
      expect(r.licenseNumber, 'LHR-15-123456');
      expect(r.dateOfExpiry, '01.01.2030');
    });

    test('ISO expiry is normalised to dd.mm.yyyy', () {
      final r = LicenseTextParser.parseLicenseText(
        'License No: RWP-987654\nExpiry: 2030-06-15',
      );
      expect(r.licenseNumber, 'RWP-987654');
      expect(r.dateOfExpiry, '15.06.2030');
    });

    test('no license data yields nothing', () {
      final r = LicenseTextParser.parseLicenseText('Hello world');
      expect(r.hasAnything, isFalse);
      expect(r.licenseNumber, isNull);
      expect(r.dateOfExpiry, isNull);
    });

    test('a bare 13-digit number is never taken as a license number', () {
      final r = LicenseTextParser.parseLicenseText(
        '3520212345671\n01.01.2030',
      );
      expect(r.licenseNumber, isNull);
      expect(r.dateOfExpiry, '01.01.2030');
    });
  });

  group('DocumentQrService — raw QR payload, never parsed', () {
    test('returns the decoded number as-is', () async {
      final service = DocumentQrService(
        analyzeImage: (_) async => 'QR-987654321',
      );
      expect(await service.readQr(File('x.jpg')), 'QR-987654321');
    });

    test('no QR code reads as null', () async {
      final service = DocumentQrService(analyzeImage: (_) async => null);
      expect(await service.readQr(File('x.jpg')), isNull);
    });

    test('a scanner failure reads as null, never throws', () async {
      final service = DocumentQrService(
        analyzeImage: (_) async => throw Exception('camera down'),
      );
      expect(await service.readQr(File('x.jpg')), isNull);
    });
  });

  group('CustomerQrCodeModel — restricted-doc round trip', () {
    test('toMap/fromMap carry the customer id and the QR number', () {
      const model = CustomerQrCodeModel(
        customerId: 'cust-3520212345671',
        qrCode: 'QR-987654321',
      );
      expect(model.toMap(), {
        'customerId': 'cust-3520212345671',
        'qrCode': 'QR-987654321',
      });
      final back = CustomerQrCodeModel.fromMap(
        model.toMap(),
        'cust-3520212345671',
      );
      expect(back.customerId, 'cust-3520212345671');
      expect(back.qrCode, 'QR-987654321');
      expect(CustomerQrCodeModel.collection, 'customer_qr_codes');
    });

    test('fromMap reads a Firestore Timestamp updatedAt', () {
      final back = CustomerQrCodeModel.fromMap({
        'customerId': 'cust-1',
        'qrCode': 'QR-1',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 11, 10)),
      });
      expect(back.qrCode, 'QR-1');
      expect(back.updatedAt, DateTime(2026, 11, 10));
    });
  });

  group('KycDraft — scan results fill the draft fields', () {
    test('applyCnicScan fills only non-null OCR fields', () {
      final draft = KycDraft()..name = 'Old Name';
      draft.applyCnicScan(
        const CnicScanResult(
          cnicNumber: '35202-1234567-1',
          dateOfBirth: '15.03.1990',
          address: 'Lahore',
        ),
      );
      expect(draft.cnic, '35202-1234567-1');
      expect(draft.dateOfBirth, '15.03.1990');
      expect(draft.address, 'Lahore');
      expect(draft.name, 'Old Name');
    });

    test('applyLicenseScan front overwrites, back only fills gaps', () {
      final draft = KycDraft()..licenseNumber = 'LHR-111';
      draft.applyLicenseScan(
        const LicenseScanResult(
          licenseNumber: 'LHR-222',
          dateOfExpiry: '01.01.2030',
        ),
        overwrite: false,
      );
      expect(draft.licenseNumber, 'LHR-111');
      expect(draft.licenseExpiry, '01.01.2030');
      draft.applyLicenseScan(
        const LicenseScanResult(licenseNumber: 'LHR-333'),
      );
      expect(draft.licenseNumber, 'LHR-333');
    });
  });

  group('CustomerQrCodeService — offline is a safe no, never a throw', () {
    test('save/get return false/null without Firebase', () async {
      final service = CustomerQrCodeService();
      expect(
        await service.saveQrCode(customerId: 'cust-1', qrCode: 'QR-1'),
        isFalse,
      );
      expect(await service.getQrCode('cust-1'), isNull);
      expect(
        await service.saveQrCode(customerId: 'cust-1', qrCode: '  '),
        isFalse,
      );
    });
  });

  group('KycCubit — QR number and license back pass through', () {
    test('submitKyc forwards qrCode, license back and license fields',
        () async {
      final repo = _FakeKycRepository();
      final cubit = KycCubit(
        uploadKycUseCase: UploadKycDocumentUseCase(repo),
      );
      await cubit.submitKyc(
        userUid: 'user-1',
        cnicNumber: '35202-1234567-1',
        cnicFront: File('front.jpg'),
        cnicBack: File('back.jpg'),
        license: File('lic-front.jpg'),
        licenseBack: File('lic-back.jpg'),
        licenseNumber: 'LHR-1234567',
        licenseExpiry: '01.01.2030',
        qrCode: 'QR-987654321',
      );
      expect(cubit.state, isA<KycSubmitted>());
      expect(repo.lastUpload?['qrCode'], 'QR-987654321');
      expect(repo.lastUpload?['licenseBack']?.path, 'lic-back.jpg');
      expect(repo.lastUpload?['licenseNumber'], 'LHR-1234567');
      expect(repo.lastUpload?['licenseExpiry'], '01.01.2030');
      await cubit.close();
    });
  });

  group('KycCustomerSaver — QR number goes to the restricted doc', () {
    test('wizard save writes the QR number apart from the customer',
        () async {
      final saved = <CustomerEntity>[];
      final qr = _FakeQrCodeService();
      final saver = KycCustomerSaver(
        saveUseCase: SaveCustomerUseCase(
          _FakeCustomerRepository(onSave: saved.add),
        ),
        blacklist: BlacklistRemoteDataSource(),
        uploader: _FakeUploader(),
        qrCodeService: qr,
      );
      final draft = KycDraft()
        ..name = 'Ahmed Ali'
        ..phone = '03001234567'
        ..cnic = '35201-4444444-4'
        ..qrCode = 'QR-4455667788';
      final result = await saver.save(shopId: 'shop-1', draft: draft);
      expect(result.customer.cnic, '35201-4444444-4');
      expect(saved, hasLength(1));
      expect(qr.lastCustomerId, 'cust-3520144444444');
      expect(qr.lastQrCode, 'QR-4455667788');
    });

    test('no QR number means no restricted-doc write', () async {
      final qr = _FakeQrCodeService();
      final saver = KycCustomerSaver(
        saveUseCase: SaveCustomerUseCase(
          _FakeCustomerRepository(onSave: (_) {}),
        ),
        blacklist: BlacklistRemoteDataSource(),
        uploader: _FakeUploader(),
        qrCodeService: qr,
      );
      final draft = KycDraft()
        ..name = 'Ahmed Ali'
        ..phone = '03001234567'
        ..cnic = '35201-4444444-4';
      await saver.save(shopId: 'shop-1', draft: draft);
      expect(qr.lastCustomerId, isNull);
    });
  });

  group('AdminPeopleDataSource — QR read is null offline', () {
    test('getCustomerQrCode returns null with no Firestore', () async {
      final ds = AdminPeopleDataSource();
      expect(await ds.getCustomerQrCode('cust-1'), isNull);
    });
  });

  group('KycSubmissionForm — camera only, QR stored silently', () {
    testWidgets('CNIC slots use the rear camera and never offer gallery',
        (tester) async {
      final repo = _FakeKycRepository();
      final cubit = KycCubit(
        uploadKycUseCase: UploadKycDocumentUseCase(repo),
      );
      addTearDown(() async => tester.runAsync(cubit.close));
      var submitted = '';
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<KycCubit>.value(
                value: cubit,
                child: KycSubmissionForm(
                  initialCnic: '',
                  existing: null,
                  userUid: 'user-1',
                  onSubmitted: (cnic) => submitted = cnic,
                  qrService: DocumentQrService(
                    analyzeImage: (_) async => 'QR-987654321',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        '35202-1234567-1',
      );
      // The focused field's blinking cursor schedules frames forever,
      // so drop focus before any pumpAndSettle.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.ensureVisible(find.text('NADRA CNIC — Front Side'));
      await tester.tap(find.text('NADRA CNIC — Front Side'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('NADRA CNIC — Back Side'));
      await tester.tap(find.text('NADRA CNIC — Back Side'));
      await tester.pumpAndSettle();
      // The QR success SnackBar sits over the submit button for 3s.
      // pumpAndSettle returns once its entrance finishes (a timer
      // schedules no frames), so advance the clock past it first.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, 2);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(find.text('Choose from gallery'), findsNothing);
      // The QR number is held for the restricted doc, never rendered.
      expect(find.text('QR Code'), findsNothing);
      expect(find.textContaining('QR-987654321'), findsNothing);

      await tester.ensureVisible(find.text('Submit KYC Documents'));
      await tester.tap(find.text('Submit KYC Documents'));
      await tester.pumpAndSettle();

      expect(submitted, '35202-1234567-1');
      expect(repo.lastUpload?['qrCode'], 'QR-987654321');
      expect(repo.lastUpload?['cnicFront']?.path, 'test/assets/mock_cnic.jpg');
      expect(repo.lastUpload?['cnicBack']?.path, 'test/assets/mock_cnic.jpg');
    });

    testWidgets('license tiles use the rear camera, no gallery',
        (tester) async {
      final repo = _FakeKycRepository();
      final cubit = KycCubit(
        uploadKycUseCase: UploadKycDocumentUseCase(repo),
      );
      addTearDown(() async => tester.runAsync(cubit.close));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<KycCubit>.value(
                value: cubit,
                child: KycSubmissionForm(
                  initialCnic: '35202-1234567-1',
                  existing: null,
                  userUid: 'user-1',
                  onSubmitted: (_) {},
                  qrService: DocumentQrService(
                    analyzeImage: (_) async => null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('License front'));
      await tester.tap(find.text('License front'));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(find.text('Choose from gallery'), findsNothing);
    });
  });

  group('Step1Cnic — back scan stores the QR number, never shows it', () {
    testWidgets('back scan uses the rear camera and stores the QR number',
        (tester) async {
      final draft = KycDraft();
      await pumpApp(
        tester,
        Step1Cnic(
          draft: draft,
          onChanged: () {},
          qrService: DocumentQrService(
            analyzeImage: (_) async => 'QR-1122334455',
          ),
        ),
      );

      await tester.tap(find.text('Scan CNIC back'));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(draft.cnicBackPhoto, isNotNull);
      expect(draft.qrCode, 'QR-1122334455');
      expect(find.text('QR Code'), findsNothing);
      expect(find.textContaining('QR-1122334455'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('front scan opens the rear camera', (tester) async {
      final draft = KycDraft();
      await pumpApp(
        tester,
        Step1Cnic(draft: draft, onChanged: () {}),
      );

      await tester.tap(find.text('Scan CNIC front'));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gallery front with an unreadable image is rejected',
        (tester) async {
      final draft = KycDraft();
      await pumpApp(
        tester,
        Step1Cnic(draft: draft, onChanged: () {}),
      );

      // The ML Kit mock returns empty text, so nothing is extractable.
      await tester.tap(find.text('Front from gallery'));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.gallery);
      expect(
        find.text(
            'This photo is not clear enough — no information could be read. Please provide a sharp, high-resolution photo with good light.'),
        findsOneWidget,
      );
      // Guarded: the unreadable gallery photo is NOT stored.
      expect(draft.cnicFrontPhoto, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gallery front with a readable image stores it and fills fields',
        (tester) async {
      final draft = KycDraft();
      await pumpApp(
        tester,
        Step1Cnic(
          draft: draft,
          onChanged: () {},
          ocrService: _FakeCnicOcrService(
            frontResult: const CnicScanResult(
              name: 'Ayesha Khan',
              fatherName: 'Muhammad Khan',
              cnicNumber: '35201-4444444-4',
              dateOfBirth: '15.03.1990',
              dateOfExpiry: '01.01.2030',
              address: 'House 1, Lahore',
            ),
            backResult: const CnicScanResult(),
          ),
        ),
      );

      await tester.tap(find.text('Front from gallery'));
      await tester.pumpAndSettle();

      expect(mockPicker.lastSource, ImageSource.gallery);
      expect(draft.cnicFrontPhoto, isNotNull);
      expect(draft.name, 'Ayesha Khan');
      expect(draft.cnic, '35201-4444444-4');
      // Thumbnail with a remove button.
      expect(find.byKey(const ValueKey('step1_cnic_front_remove')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gallery back with no QR and no readable text is rejected',
        (tester) async {
      final draft = KycDraft();
      await pumpApp(
        tester,
        Step1Cnic(
          draft: draft,
          onChanged: () {},
          qrService: DocumentQrService(
            analyzeImage: (_) async => null,
          ),
        ),
      );

      await tester.tap(find.text('Back from gallery'));
      await tester.pumpAndSettle();

      expect(mockPicker.lastSource, ImageSource.gallery);
      expect(
        find.text(
            'This photo is not clear enough — no information could be read. Please provide a sharp, high-resolution photo with good light.'),
        findsOneWidget,
      );
      expect(draft.cnicBackPhoto, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gallery back with a QR code stores the photo and the number',
        (tester) async {
      final draft = KycDraft();
      await pumpApp(
        tester,
        Step1Cnic(
          draft: draft,
          onChanged: () {},
          qrService: DocumentQrService(
            analyzeImage: (_) async => 'QR-9988776655',
          ),
        ),
      );

      await tester.tap(find.text('Back from gallery'));
      await tester.pumpAndSettle();

      expect(mockPicker.lastSource, ImageSource.gallery);
      expect(draft.cnicBackPhoto, isNotNull);
      expect(draft.qrCode, 'QR-9988776655');
      expect(find.byKey(const ValueKey('step1_cnic_back_remove')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('remove clears the back photo and its QR number',
        (tester) async {
      final draft = KycDraft()
        ..cnicBackPhoto = XFile('test/assets/mock_cnic.jpg')
        ..qrCode = 'QR-9988776655';
      await pumpApp(
        tester,
        Step1Cnic(draft: draft, onChanged: () {}),
      );

      await tester.tap(find.byKey(const ValueKey('step1_cnic_back_remove')));
      await tester.pumpAndSettle();

      expect(draft.cnicBackPhoto, isNull);
      expect(draft.qrCode, isEmpty);
      expect(find.byKey(const ValueKey('step1_cnic_back_remove')),
          findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('remove clears the front photo', (tester) async {
      final draft = KycDraft()
        ..cnicFrontPhoto = XFile('test/assets/mock_cnic.jpg');
      await pumpApp(
        tester,
        Step1Cnic(draft: draft, onChanged: () {}),
      );

      await tester.tap(find.byKey(const ValueKey('step1_cnic_front_remove')));
      await tester.pumpAndSettle();

      expect(draft.cnicFrontPhoto, isNull);
      expect(find.byKey(const ValueKey('step1_cnic_front_remove')),
          findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Step3Docs — license tiles are camera-only', () {
    testWidgets('license front opens the rear camera with no sheet',
        (tester) async {
      final draft = KycDraft();
      await pumpApp(
        tester,
        Step3Docs(draft: draft, onChanged: () {}),
      );

      await tester.tap(
        find.byKey(const ValueKey('step3_license_front')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Take Photo (Back Camera)'), findsNothing);
      expect(find.text('Choose from Gallery'), findsNothing);
      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(draft.licenseFrontPhoto, isNotNull);
      expect(find.text('QR Code'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('MediaPickerHelper — cameraOnly', () {
    testWidgets('cameraOnly opens the rear camera with no sheet',
        (tester) async {
      XFile? selected;
      mockPicker.mockResult = XFile('test/assets/mock_doc.jpg');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MediaPickerHelper.showMediaSourceSheet(
                    context: context,
                    cameraOnly: true,
                    onImageSelected: (file) => selected = file,
                  );
                },
                child: const Text('Capture'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Capture'));
      await tester.pumpAndSettle();

      expect(find.text('Select Media Source'), findsNothing);
      expect(find.text('Choose from Gallery'), findsNothing);
      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(selected?.path, 'test/assets/mock_doc.jpg');
    });
  });

  group('AdminQrCodeRow — super admin only', () {
    testWidgets('renders the number for a super admin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: AdminQrCodeRow(
              isSuperAdmin: true,
              qrCode: 'QR-9988776655',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QR Code: QR-9988776655'), findsOneWidget);
    });

    testWidgets('renders nothing for operations/support', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: AdminQrCodeRow(
              isSuperAdmin: false,
              qrCode: 'QR-9988776655',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('QR-9988776655'), findsNothing);
      expect(find.text('QR Code'), findsNothing);
    });

    testWidgets('renders nothing when there is no number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminQrCodeRow(isSuperAdmin: true, qrCode: null),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QR Code'), findsNothing);
    });
  });

  group('AdminCustomerDetailView — QR gating by role', () {
    CustomerDetail cannedDetail() => CustomerDetail(
          customer: CustomerEntity(
            customerId: 'cust-1',
            shopId: 'shop-1',
            name: 'Ahmed Ali',
            phone: '03001234567',
            cnic: '35202-1234567-1',
            createdAt: DateTime(2026, 1, 1),
          ),
          storedTrustScore: 3.5,
          isBlacklisted: false,
          kycStatus: 'submitted',
          bookings: const [],
          completedTrips: 0,
          meanOwnerRating: null,
          trustBreakdown: const TrustScoreBreakdown(
            base: 2.5,
            kyc: 1.0,
            trips: 0,
            ratings: 0,
            punctuality: 0,
            conduct: 0,
            total: 3.5,
          ),
          blacklistRecord: null,
          notes: const [],
        );

    testWidgets('operations never triggers a QR read', (tester) async {
      var qrLoadCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminCustomerDetailView(
            customerId: 'cust-1',
            loadDetail: (_) async => cannedDetail(),
            resolveAdminRole: () async => 'operations',
            loadQrCode: (_) async {
              qrLoadCalled = true;
              return 'QR-9988776655';
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(qrLoadCalled, isFalse);
      expect(find.textContaining('QR-9988776655'), findsNothing);
      expect(find.text('QR Code'), findsNothing);
    });

    testWidgets('super admin sees the QR number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminCustomerDetailView(
            customerId: 'cust-1',
            loadDetail: (_) async => cannedDetail(),
            resolveAdminRole: () async => 'super_admin',
            loadQrCode: (_) async => 'QR-9988776655',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QR Code: QR-9988776655'), findsOneWidget);
    });
  });

  group('OwnerCustomerDetailView — never renders the QR number', () {
    testWidgets('offline error state shows no QR Code text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerCustomerDetailView(
            customerId: 'no-such',
            shopId: 'shop-1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QR Code'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('OwnerCnicReviewView — back scan stores the QR number', () {
    testWidgets('back scan uses the rear camera, number never shown',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerCnicReviewView(
            initial: const CnicScanResult(
              name: 'Ahmed Ali',
              cnicNumber: '35202-1234567-1',
            ),
            qrService: DocumentQrService(
              analyzeImage: (_) async => 'QR-5566778899',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Scan Back of CNIC (address)'));
      await tester.tap(find.text('Scan Back of CNIC (address)'));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(find.text('QR Code'), findsNothing);
      expect(find.textContaining('QR-5566778899'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeKycRepository implements KycRepository {
  Map<String, dynamic>? lastUpload;

  @override
  Future<KycDocumentEntity?> getKyc(String userUid) async => null;

  @override
  Future<KycDocumentEntity> uploadKycDocuments({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
    File? licenseBack,
    String? licenseNumber,
    String? licenseExpiry,
    String? qrCode,
    String? previousStatus,
  }) async {
    lastUpload = {
      'userUid': userUid,
      'cnicNumber': cnicNumber,
      'cnicFront': cnicFront,
      'cnicBack': cnicBack,
      'license': license,
      'licenseBack': licenseBack,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry,
      'qrCode': qrCode,
    };
    return KycDocumentEntity(
      userUid: userUid,
      cnicNumber: cnicNumber,
      cnicFrontKey: 'front',
      cnicBackKey: 'back',
      licenseKey: 'lic',
      licenseBackKey: 'lic-back',
      licenseNumber: licenseNumber ?? '',
      licenseExpiry: licenseExpiry ?? '',
    );
  }
}

class _FakeCustomerRepository implements CustomerRepository {
  final void Function(CustomerEntity customer) onSave;

  _FakeCustomerRepository({required this.onSave});

  @override
  Future<List<CustomerEntity>> getShopCustomers(String shopId) async => [];

  @override
  Future<CustomerEntity?> getCustomerByCnic(
    String shopId,
    String cnic,
  ) async =>
      null;

  @override
  Future<void> upsertCustomer(CustomerEntity customer) async =>
      onSave(customer);

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

class _FakeUploader extends KycMediaUploadService {
  @override
  Future<KycUploadResult> uploadAll({
    required String shopId,
    required String customerId,
    required KycDraft draft,
  }) async =>
      KycUploadResult();
}

class _FakeQrCodeService extends CustomerQrCodeService {
  String? lastCustomerId;
  String? lastQrCode;

  @override
  Future<bool> saveQrCode({
    required String customerId,
    required String qrCode,
  }) async {
    lastCustomerId = customerId;
    lastQrCode = qrCode;
    return true;
  }
}
