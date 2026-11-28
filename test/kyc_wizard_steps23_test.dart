import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step2_photo.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step3_docs.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

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

  /// Rear-camera picks: the thumbprint and license tiles open the
  /// rear camera directly (camera-only KYC rule, no sheet, no
  /// gallery); other pickers go through the media source sheet.
  Future<void> tapRearCamera(WidgetTester tester, Key buttonKey) async {
    await tester.ensureVisible(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    if (find.text('Take Photo (Back Camera)').evaluate().isNotEmpty) {
      await tester.tap(find.text('Take Photo (Back Camera)'));
      await tester.pumpAndSettle();
    }
  }

  /// License tiles show a spinner while OCR runs; the OCR future
  /// never completes under the fake clock (ML Kit channel), so
  /// pumpAndSettle would time out on the spinner — pump fixed
  /// frames instead. The photo is stored before OCR starts, so
  /// the draft assertions still hold.
  Future<void> tapLicenseCamera(WidgetTester tester, Key buttonKey) async {
    await tester.ensureVisible(find.byKey(buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
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

    testWidgets('left-hand photo uses the REAR camera directly (no gallery)',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step2Photo(draft: draft, onChanged: () {}));

      await tapRearCamera(tester, const ValueKey('step2_finger_left_scan'));

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(draft.leftFingersPhoto, isNotNull);
      expect(draft.hasLeftFingerprints, isTrue);
      expect(find.byKey(const ValueKey('step2_finger_left_retake')),
          findsOneWidget);
    });

    testWidgets('right-hand photo uses the REAR camera directly (no gallery)',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step2Photo(draft: draft, onChanged: () {}));

      await tapRearCamera(tester, const ValueKey('step2_finger_right_scan'));

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      expect(draft.rightFingersPhoto, isNotNull);
      expect(draft.hasRightFingerprints, isTrue);
      expect(find.byKey(const ValueKey('step2_finger_right_retake')),
          findsOneWidget);
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

    testWidgets('validate fails with face but only one hand',
        (tester) async {
      final key = GlobalKey<Step2PhotoState>();
      final draft = KycDraft()
        ..facePhoto = XFile('test/assets/mock_selfie.jpg')
        ..leftFingersPhoto = XFile('test/assets/mock_fingers_left.jpg');
      await pumpStep(tester, Step2Photo(key: key, draft: draft, onChanged: () {}));

      expect(await key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(
        find.text('Fingerprints of both hands are required to continue'),
        findsOneWidget,
      );
    });

    testWidgets('validate passes with face + both hands', (tester) async {
      final key = GlobalKey<Step2PhotoState>();
      final draft = KycDraft()
        ..facePhoto = XFile('test/assets/mock_selfie.jpg')
        ..leftFingersPhoto = XFile('test/assets/mock_fingers_left.jpg')
        ..rightFingersPhoto = XFile('test/assets/mock_fingers_right.jpg');
      await pumpStep(tester, Step2Photo(key: key, draft: draft, onChanged: () {}));

      expect(await key.currentState!.validate(), isTrue);
    });

    testWidgets('face photo can be removed to retake it', (tester) async {
      final draft = KycDraft()
        ..facePhoto = XFile('test/assets/mock_selfie.jpg');
      await pumpStep(tester, Step2Photo(draft: draft, onChanged: () {}));

      await tester.tap(find.byKey(const ValueKey('step2_face_remove')));
      await tester.pumpAndSettle();

      expect(draft.facePhoto, isNull);
      expect(draft.hasFacePhoto, isFalse);
      expect(find.byKey(const ValueKey('step2_face_remove')), findsNothing);
      expect(find.byKey(const ValueKey('step2_face_take')), findsOneWidget);
    });

    testWidgets('finger photos can be removed to retake them',
        (tester) async {
      final draft = KycDraft()
        ..leftFingersPhoto = XFile('test/assets/mock_fingers_left.jpg')
        ..rightFingersPhoto = XFile('test/assets/mock_fingers_right.jpg');
      await pumpStep(tester, Step2Photo(draft: draft, onChanged: () {}));

      await tester.ensureVisible(
          find.byKey(const ValueKey('step2_finger_left_remove')));
      await tester.tap(
          find.byKey(const ValueKey('step2_finger_left_remove')));
      await tester.pumpAndSettle();
      expect(draft.leftFingersPhoto, isNull);
      expect(draft.rightFingersPhoto, isNotNull);

      await tester.ensureVisible(
          find.byKey(const ValueKey('step2_finger_right_remove')));
      await tester.tap(
          find.byKey(const ValueKey('step2_finger_right_remove')));
      await tester.pumpAndSettle();
      expect(draft.rightFingersPhoto, isNull);
      expect(draft.hasRightFingerprints, isFalse);
    });
  });

  group('Step3Docs', () {
    testWidgets('license front/back capture via the rear camera',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      await tapLicenseCamera(tester, const ValueKey('step3_license_front'));
      expect(draft.licenseFrontPhoto, isNotNull);
      expect(draft.hasLicenseFront, isTrue);

      await tapLicenseCamera(tester, const ValueKey('step3_license_back'));
      expect(draft.licenseBackPhoto, isNotNull);
      expect(draft.hasLicenseBack, isTrue);
      expect(mockPicker.callCount, 2);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
    });

    testWidgets('license photos can be removed to retake them',
        (tester) async {
      final draft = KycDraft()
        ..licenseFrontPhoto = XFile('test/assets/mock_lic_front.jpg')
        ..licenseBackPhoto = XFile('test/assets/mock_lic_back.jpg');
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      await tester.ensureVisible(
          find.byKey(const ValueKey('step3_license_front_remove')));
      await tester.tap(
          find.byKey(const ValueKey('step3_license_front_remove')));
      await tester.pumpAndSettle();
      expect(draft.licenseFrontPhoto, isNull);
      expect(draft.licenseBackPhoto, isNotNull);
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
