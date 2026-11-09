import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step2_photo.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step3_docs.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:signature/signature.dart';

import 'test_helper.dart';

/// Wizard steps 2 + 3 (W3): live photo + thumbprint, license/docs/
/// signature/terms. The camera is mocked with [MockImagePickerPlatform];
/// the mock returns an [XFile] path only — the widgets render it with
/// an errorBuilder, so the (nonexistent) file never fails a test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockImagePickerPlatform mockPicker;

  setUp(() {
    mockPicker = MockImagePickerPlatform.setup();
    mockPicker.mockResult = XFile('test/assets/mock_selfie.jpg');
  });

  tearDown(() {
    MockImagePickerPlatform.tearDown();
  });

  Future<void> pumpStep(WidgetTester tester, Widget step) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: step,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Rear-camera picks go through the media source sheet.
  Future<void> tapRearCamera(WidgetTester tester, Key buttonKey) async {
    await tester.ensureVisible(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    expect(find.text('Take Photo (Back Camera)'), findsOneWidget);
    await tester.tap(find.text('Take Photo (Back Camera)'));
    await tester.pumpAndSettle();
  }

  group('Step2Photo', () {
    testWidgets('face Take photo uses the FRONT camera and shows the photo',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step2Photo(draft: draft, onChanged: () {}));

      await tester.tap(find.byKey(const ValueKey('step2_face_take')));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.front);
      expect(draft.facePhoto, isNotNull);
      expect(draft.facePhoto!.path, 'test/assets/mock_selfie.jpg');
      expect(draft.hasFacePhoto, isTrue);
      expect(find.byKey(const ValueKey('step2_face_retake')), findsOneWidget);
    });

    testWidgets('thumbprint Take photo uses the REAR camera via the sheet',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step2Photo(draft: draft, onChanged: () {}));

      await tapRearCamera(tester, const ValueKey('step2_thumb_take'));

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(draft.thumbprintPhoto, isNotNull);
      expect(draft.hasThumbprint, isTrue);
      expect(find.byKey(const ValueKey('step2_thumb_retake')), findsOneWidget);
    });

    testWidgets('validate fails with no photos', (tester) async {
      final key = GlobalKey<Step2PhotoState>();
      await pumpStep(
        tester,
        Step2Photo(key: key, draft: KycDraft(), onChanged: () {}),
      );

      expect(await key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('A photo is required to continue'), findsOneWidget);
    });

    testWidgets('validate passes with face + thumbprint', (tester) async {
      final key = GlobalKey<Step2PhotoState>();
      final draft = KycDraft()
        ..facePhoto = XFile('test/assets/mock_selfie.jpg')
        ..thumbprintPhoto = XFile('test/assets/mock_thumb.jpg');
      await pumpStep(tester, Step2Photo(key: key, draft: draft, onChanged: () {}));

      expect(await key.currentState!.validate(), isTrue);
    });
  });

  group('Step3Docs', () {
    testWidgets('license front/back capture via the rear camera',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      await tapRearCamera(tester, const ValueKey('step3_license_front'));
      expect(draft.licenseFrontPhoto, isNotNull);
      expect(draft.hasLicenseFront, isTrue);

      await tapRearCamera(tester, const ValueKey('step3_license_back'));
      expect(draft.licenseBackPhoto, isNotNull);
      expect(draft.hasLicenseBack, isTrue);
      expect(mockPicker.callCount, 2);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
    });

    testWidgets('utility bill capture stores the photo', (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      await tapRearCamera(tester, const ValueKey('step3_bill'));

      expect(draft.utilityBillPhoto, isNotNull);
      expect(draft.hasUtilityBill, isTrue);
    });

    testWidgets('extra docs add then remove', (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      await tapRearCamera(tester, const ValueKey('step3_extra_add'));
      expect(draft.extraPhotos.length, 1);

      await tapRearCamera(tester, const ValueKey('step3_extra_add'));
      expect(draft.extraPhotos.length, 2);

      await tester.ensureVisible(find.byKey(const ValueKey('step3_extra_remove_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step3_extra_remove_0')));
      await tester.pumpAndSettle();
      expect(draft.extraPhotos.length, 1);
    });

    testWidgets('signature Confirm stores PNG bytes', (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      expect(find.byType(Signature), findsOneWidget);
      await tester.ensureVisible(find.byType(Signature));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Signature), const Offset(100, 5));
      await tester.pump();

      // toPngBytes rasterizes through the engine: real async work that
      // only completes when the test binding runs real async, so give
      // it a real delay inside runAsync after the tap.
      await tester.ensureVisible(find.byKey(const ValueKey('step3_signature_confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step3_signature_confirm')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      expect(draft.signaturePng, isNotNull);
      expect(draft.signaturePng!, isNotEmpty);
      expect(draft.hasSignature, isTrue);
      // Signed state: the pad is replaced by the saved signature.
      expect(find.byKey(const ValueKey('step3_signature_confirm')), findsNothing);
    });

    testWidgets('signature Confirm with an empty pad stores nothing',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      await tester.ensureVisible(find.byKey(const ValueKey('step3_signature_confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step3_signature_confirm')));
      await tester.pumpAndSettle();

      expect(draft.signaturePng, isNull);
      expect(draft.hasSignature, isFalse);
    });

    testWidgets('terms checkbox gates validate()', (tester) async {
      final key = GlobalKey<Step3DocsState>();
      final draft = KycDraft()
        ..licenseFrontPhoto = XFile('test/assets/mock_lic_front.jpg')
        ..licenseBackPhoto = XFile('test/assets/mock_lic_back.jpg')
        ..utilityBillPhoto = XFile('test/assets/mock_bill.jpg')
        ..signaturePng = Uint8List.fromList([1, 2, 3]);
      await pumpStep(tester, Step3Docs(key: key, draft: draft, onChanged: () {}));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'LHR-1234567');
      await tester.enterText(fields.at(1), '01.01.2030');
      await tester.pump();

      expect(draft.licenseNumber, 'LHR-1234567');
      expect(draft.licenseExpiry, '01.01.2030');
      expect(await key.currentState!.validate(), isFalse);

      await tester.ensureVisible(find.byKey(const ValueKey('step3_terms_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step3_terms_checkbox')));
      await tester.pump();
      expect(draft.termsAgreed, isTrue);
      expect(await key.currentState!.validate(), isTrue);
    });

    testWidgets('invalid license expiry fails validate()', (tester) async {
      final key = GlobalKey<Step3DocsState>();
      final draft = KycDraft()
        ..licenseFrontPhoto = XFile('test/assets/mock_lic_front.jpg')
        ..licenseBackPhoto = XFile('test/assets/mock_lic_back.jpg')
        ..utilityBillPhoto = XFile('test/assets/mock_bill.jpg')
        ..signaturePng = Uint8List.fromList([1, 2, 3])
        ..termsAgreed = true;
      await pumpStep(tester, Step3Docs(key: key, draft: draft, onChanged: () {}));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'LHR-1234567');
      await tester.enterText(fields.at(1), '32.13.2030');
      await tester.pump();

      expect(await key.currentState!.validate(), isFalse);
    });

    testWidgets('View Terms dialog shows the three contract terms',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      await tester.ensureVisible(find.byKey(const ValueKey('step3_view_terms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step3_view_terms')));
      await tester.pumpAndSettle();

      expect(
        find.text('Legal Terms & Conditions (Pakistan Jurisdiction):'),
        findsOneWidget,
      );
      // Audit §3 item 14: contractTerm1 was replaced by the registrar
      // with the city-limits / out-city-rate wording.
      expect(find.textContaining('within city limits'), findsOneWidget);
      expect(find.textContaining('Traffic challans'), findsOneWidget);
      expect(find.textContaining('non-bailable FIR'), findsOneWidget);
    });
  });
}
