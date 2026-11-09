import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/owner/presentation/views/add_customer/step1_cnic.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step2_photo.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_add_customer_wizard.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add Customer wizard (O11) — step 1: CNIC + identity, blacklist
// check, and the keyboard-visibility contract for the last field.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  Future<void> pumpWizard(WidgetTester tester, {String? cnic}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OwnerAddCustomerWizard(prefilledCnic: cnic),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('KYC wizard — step 1 (CNIC)', () {
    testWidgets('wizard opens on step 1 with the prefilled CNIC',
        (tester) async {
      await pumpWizard(tester, cnic: '35201-1234567-1');
      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.byType(Step1Cnic), findsOneWidget);
      final cnicField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'CNIC Number'));
      expect(cnicField.controller?.text, '35201-1234567-1');
    });

    testWidgets('Next with empty name/phone does not advance',
        (tester) async {
      await pumpWizard(tester, cnic: '35201-1234567-1');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byType(Step1Cnic), findsOneWidget);
      expect(find.byType(Step2Photo), findsNothing);
    });

    testWidgets('valid step 1 + clean blacklist advances to step 2',
        (tester) async {
      await pumpWizard(tester, cnic: '35201-1234567-1');
      await tester.enterText(
          find.widgetWithText(TextField, 'Full name'), 'Muhammad Ahmed');
      await tester.enterText(find.widgetWithText(TextField, 'WhatsApp number'),
          '0300-1234567');
      await tester.ensureVisible(find.text('Verify CNIC & Blacklist'));
      await tester.tap(find.text('Verify CNIC & Blacklist'));
      await tester.pumpAndSettle();
      expect(find.text('No blacklist record found'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byType(Step2Photo), findsOneWidget);
      expect(find.byType(Step1Cnic), findsNothing);
    });

    testWidgets(
        'keyboard open keeps the focused WhatsApp field fully visible',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpWizard(tester, cnic: '35201-1234567-1');
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      await tester.pump();
      final phoneField =
          find.widgetWithText(TextField, 'WhatsApp number');
      await tester.showKeyboard(phoneField);
      await tester.pumpAndSettle();
      final rect = tester.getRect(phoneField);
      final headerBottom = tester
          .getRect(find.byKey(const Key('kyc-stepper-header')))
          .bottom;
      expect(rect.top, greaterThanOrEqualTo(headerBottom));
      expect(rect.bottom, lessThanOrEqualTo(800 - 400));
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
    });
  });
}
