import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentalhub/core/constants/app_colors.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_info_box.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step2_photo.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step3_docs.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step4_guarantor.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_add_customer_wizard.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

import 'test_helper.dart';

/// Visual fixes for the untouched owner views (2026-11-14 pass):
/// wizard shared padding, stepper Urdu truncation, step-1 success
/// colour + scan-button heights, step-2 finger photos (rear camera
/// only, no gallery), step-3 filled fields + license-OCR feedback +
/// 48dp remove target, step-4 token info boxes + relation hint.
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

  Future<void> pumpWizard(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const OwnerAddCustomerWizard(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpStep(
    WidgetTester tester,
    Widget step, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: step),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Wizard shell padding + Urdu stepper', () {
    testWidgets('steps share one 16px outer padding from the shell',
        (tester) async {
      await pumpWizard(tester);
      // The shell wraps _currentStep() in a single 16px Padding
      // inside its scroll view — that is the padding steps 2–4
      // were missing (step 1 used to carry its own).
      final shellPadding = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byWidgetPredicate(
          (w) => w is Padding && w.padding == const EdgeInsets.all(16),
        ),
      );
      expect(shellPadding, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Urdu stepper labels render at 360px without overflow',
        (tester) async {
      await pumpWizard(
        tester,
        locale: const Locale('ur'),
        textScale: 1.3,
      );
      // The longest Urdu label ("دستاویزات اور دستخط") used to
      // truncate to an ellipsis on one line at 360px. Scope to the
      // stepper header — the app-bar subtitle repeats step 1's label.
      final stepper = find.byKey(const Key('kyc-stepper-header'));
      expect(
        find.descendant(of: stepper, matching: find.text('دستاویزات اور دستخط')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stepper, matching: find.text('شناختی کارڈ')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stepper, matching: find.text('ضامن')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('step-1 scan buttons share one height in Urdu',
        (tester) async {
      await pumpWizard(tester, locale: const Locale('ur'));
      final front = tester.getSize(find.text('شناختی کارڈ کا سامنے والا حصہ اسکین کریں'));
      final back = tester.getSize(find.text('شناختی کارڈ کا پچھلا حصہ اسکین کریں'));
      // Both buttons stretch to the same height even though the
      // two Urdu labels wrap to different line counts.
      expect(front.height, back.height);
      expect(tester.takeException(), isNull);
    });
  });

  group('Step2Photo fingerprints', () {
    testWidgets('finger photos use the REAR camera with no gallery sheet',
        (tester) async {
      final draft = KycDraft();
      await pumpStep(tester, Step2Photo(draft: draft, onChanged: () {}));

      await tester.tap(find.byKey(const ValueKey('step2_finger_left_scan')));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, 1);
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
      // No media-source sheet ever appeared.
      expect(find.text('Take Photo (Back Camera)'), findsNothing);
      expect(find.text('Choose from Gallery'), findsNothing);
      expect(draft.leftFingersPhoto, isNotNull);
      expect(draft.hasLeftFingerprints, isTrue);
    });
  });

  group('Step3Docs', () {
    testWidgets('extra-doc remove target is at least 48dp', (tester) async {
      final draft = KycDraft()
        ..extraPhotos.add(XFile('test/assets/mock_selfie.jpg'));
      await pumpStep(tester, Step3Docs(draft: draft, onChanged: () {}));

      final remove = find.byKey(const ValueKey('step3_extra_remove_0'));
      expect(remove, findsOneWidget);
      final size = tester.getSize(remove);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('license fields are filled like step 1', (tester) async {
      await pumpStep(tester, Step3Docs(draft: KycDraft(), onChanged: () {}));

      // The two license TextFormFields build TextFields — both
      // must carry the same filled style as step 1's fields.
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.length, 2);
      for (final field in fields) {
        expect(field.decoration?.filled, isTrue);
        expect(field.decoration?.fillColor, isNotNull);
      }
    });
  });

  group('Step4Guarantor', () {
    testWidgets('relation dropdown explains it needs a guarantor first',
        (tester) async {
      await pumpStep(
        tester,
        Step4Guarantor(draft: KycDraft(), onChanged: () {}, shopId: 'shop-1'),
      );

      expect(
        find.text('Choose a guarantor above to set the relation'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('KycInfoBox', () {
    testWidgets('success tone uses the theme success tokens, not raw green',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KycInfoBox(
              tone: KycInfoTone.success,
              icon: Icons.check_circle_rounded,
              text: 'on file',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(KycInfoBox),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.color,
        AppColors.successContainerFor(Brightness.light),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
