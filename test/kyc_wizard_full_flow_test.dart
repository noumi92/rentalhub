import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_media_upload_service.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step2_photo.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step3_docs.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step4_guarantor.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_add_customer_wizard.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_added_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:signature/signature.dart';

import 'test_helper.dart';

/// Full 4-step wizard flow: prefilled CNIC → step 1 (CNIC) → step 2
/// (photo) → step 3 (docs + signature + terms) → step 4 (no
/// guarantor — optional) → Save → O13 success screen, with the saved
/// record carrying the wizard fields.
///
/// Uploads are faked with canned URLs: the mock picker returns paths
/// that do not exist on disk, so the real uploader would fail them
/// and the save would abort. The blacklist is the real in-memory one
/// (clean for this CNIC).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockImagePickerPlatform mockPicker;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    if (di.sl.isRegistered<KycMediaUploadService>()) {
      di.sl.unregister<KycMediaUploadService>();
    }
    di.sl.registerSingleton<KycMediaUploadService>(_FakeUploader());
  });

  setUp(() {
    mockPicker = MockImagePickerPlatform.setup();
    mockPicker.mockResult = XFile('test/assets/mock_selfie.jpg');
  });

  tearDown(() {
    MockImagePickerPlatform.tearDown();
  });

  /// License tiles show a spinner while OCR runs; the OCR future
  /// never completes under the fake clock (ML Kit channel), so
  /// pumpAndSettle would time out on the spinner — pump fixed
  /// frames instead. The photo is stored before OCR starts.
  Future<void> tapLicenseCamera(WidgetTester tester, Key buttonKey) async {
    await tester.ensureVisible(find.byKey(buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Same fixed-frame pumping for a sheet-based pick made while
  /// the license spinners are still animating (e.g. the bill tile
  /// on step 3): no pumpAndSettle until step 3 leaves the tree.
  Future<void> tapSheetCamera(WidgetTester tester, Key buttonKey) async {
    await tester.ensureVisible(find.byKey(buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('Take Photo (Back Camera)').evaluate().isNotEmpty) {
      await tester.tap(find.text('Take Photo (Back Camera)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('full wizard flow saves the customer and lands on the success screen',
      (tester) async {
    const cnic = '35201-4444444-4';
    final router = GoRouter(
      initialLocation: '/owner/customers/add?cnic=$cnic',
      routes: [
        GoRoute(
          path: '/owner/customers/add',
          builder: (context, state) => OwnerAddCustomerWizard(
            prefilledCnic: state.uri.queryParameters['cnic'],
          ),
        ),
        // Finish build (O13): save now lands on the success screen,
        // not the list — the list is one tap away from there.
        GoRoute(
          path: '/owner/customers/added/:id',
          builder: (context, state) => OwnerCustomerAddedView(
            customerId: state.pathParameters['id']!,
            customer: state.extra as CustomerEntity?,
          ),
        ),
        GoRoute(
          path: '/owner/customers',
          builder: (context, state) =>
              const OwnerCustomersListView(shopId: 'shop-1'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: CNIC prefilled; fill name + phone, verify, Next.
    expect(find.text('Add Customer'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'CNIC Number'))
          .controller
          ?.text,
      cnic,
    );
    await tester.enterText(
        find.widgetWithText(TextField, 'Full name'), 'Ayesha Khan');
    await tester.enterText(
        find.widgetWithText(TextField, 'WhatsApp number'), '0300-4444444');
    await tester.ensureVisible(find.text('Verify CNIC & Blacklist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify CNIC & Blacklist'));
    await tester.pumpAndSettle();
    expect(find.text('No blacklist record found'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 2: face (front camera) + finger photos (rear camera,
    // left + right hand). The finger sections sit below
    // the fold at the default test size — scroll them into view
    // first or the taps miss and validation keeps us on step 2.
    // (The face button needs the same treatment: the scroll view
    // keeps step 1's scrolled-down offset when the step changes,
    // so it starts above the viewport.)
    expect(find.byType(Step2Photo), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('step2_face_take')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('step2_face_take')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('step2_finger_left_scan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('step2_finger_left_scan')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('step2_finger_right_scan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('step2_finger_right_scan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 3: license front/back + bill, number + expiry, signature,
    // terms.
    expect(find.byType(Step3Docs), findsOneWidget);
    await tapLicenseCamera(tester, const ValueKey('step3_license_front'));
    await tapLicenseCamera(tester, const ValueKey('step3_license_back'));
    await tapSheetCamera(tester, const ValueKey('step3_bill'));
    final licenseFields = find.byType(TextFormField);
    await tester.enterText(licenseFields.at(0), 'LHR-1234567');
    await tester.enterText(licenseFields.at(1), '01.01.2030');
    await tester.pump();
    await tester.ensureVisible(find.byType(Signature));
    // Fixed frames, not settle: the license spinners are still
    // animating (OCR never completes under the fake clock).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.byType(Signature), const Offset(100, 5));
    await tester.pump();
    await tester.ensureVisible(
        find.byKey(const ValueKey('step3_signature_confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('step3_signature_confirm')));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(
        find.byKey(const ValueKey('step3_terms_checkbox')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('step3_terms_checkbox')));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 4: no guarantor (optional) — Save.
    expect(find.byType(Step4Guarantor), findsOneWidget);
    expect(find.text('Search existing customers'), findsOneWidget);
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();

    // Lands on the O13 success screen with the new customer ready
    // to book; the saved record carries the wizard fields.
    expect(find.text('Customer added'), findsOneWidget);
    expect(find.text('Ayesha Khan'), findsOneWidget);
    final saved = await di.sl<CustomerRemoteDataSource>()
        .getCustomerByCnic('shop-1', cnic);
    expect(saved?.name, 'Ayesha Khan');
    expect(saved?.phone, '0300-4444444');
    expect(saved?.profilePhotoUrl, 'https://cdn.example/kyc/face.jpg');
    expect(saved?.thumbprintUrl, isNull);
    expect(saved?.leftFingerprintUrl,
        'https://cdn.example/kyc/finger-left.jpg');
    expect(saved?.rightFingerprintUrl,
        'https://cdn.example/kyc/finger-right.jpg');
    expect(saved?.licenseFrontUrl, 'https://cdn.example/kyc/lic-front.jpg');
    expect(saved?.licenseBackUrl, 'https://cdn.example/kyc/lic-back.jpg');
    expect(saved?.utilityBillUrl, 'https://cdn.example/kyc/bill.jpg');
    expect(saved?.licenseNumber, 'LHR-1234567');
    expect(saved?.licenseExpiry, '01.01.2030');
    expect(saved?.signatureUrl, 'https://cdn.example/kyc/signature.png');
    // Step 1 was manual entry (no CNIC scan), so no CNIC photo URLs.
    expect(saved?.cnicFrontUrl, isNull);
  });
}

/// Canned uploads: every file the draft carries gets a fixed URL.
class _FakeUploader extends KycMediaUploadService {
  @override
  Future<KycUploadResult> uploadAll({
    required String shopId,
    required String customerId,
    required KycDraft draft,
  }) async {
    final result = KycUploadResult();
    if (draft.facePhoto != null) {
      result.urls['profilePhotoUrl'] = 'https://cdn.example/kyc/face.jpg';
    }
    if (draft.thumbprintPhoto != null) {
      result.urls['thumbprintUrl'] = 'https://cdn.example/kyc/thumb.jpg';
    }
    if (draft.leftFingersPhoto != null) {
      result.urls['leftFingerprintUrl'] =
          'https://cdn.example/kyc/finger-left.jpg';
    }
    if (draft.rightFingersPhoto != null) {
      result.urls['rightFingerprintUrl'] =
          'https://cdn.example/kyc/finger-right.jpg';
    }
    if (draft.cnicFrontPhoto != null) {
      result.urls['cnicFrontUrl'] = 'https://cdn.example/kyc/cnic-front.jpg';
    }
    if (draft.cnicBackPhoto != null) {
      result.urls['cnicBackUrl'] = 'https://cdn.example/kyc/cnic-back.jpg';
    }
    if (draft.licenseFrontPhoto != null) {
      result.urls['licenseFrontUrl'] =
          'https://cdn.example/kyc/lic-front.jpg';
    }
    if (draft.licenseBackPhoto != null) {
      result.urls['licenseBackUrl'] = 'https://cdn.example/kyc/lic-back.jpg';
    }
    if (draft.utilityBillPhoto != null) {
      result.urls['utilityBillUrl'] = 'https://cdn.example/kyc/bill.jpg';
    }
    if (draft.signaturePng != null && draft.signaturePng!.isNotEmpty) {
      result.urls['signatureUrl'] = 'https://cdn.example/kyc/signature.png';
    }
    return result;
  }
}
