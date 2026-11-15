// UI/UX audit 2026-11-15 (Team A) — theme / contrast / labels / admin.
//
// Widget + scan tests for the Team A findings: AC-1/AC-2/AC-3/AC-6/AC-7,
// AC-9, AC-10, AC-15, AC-16, AC-17, AC-20, FG-13/PW-10 (partly — the QR
// pass tests live in ui_dark_mode_widgets_test.dart), DS-1, DS-8, AC-4,
// AC-5. Pure widget tests — no DI, no Firebase.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/core/widgets/minimal_app_bar.dart';
import 'package:rentalhub/core/widgets/signature_pad.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_kpi_card.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_login_form.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_team_member_tile.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_totp_step.dart';
import 'package:rentalhub/features/auth/presentation/views/widgets/auth_stepper_bar.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/whatsapp_log_tile.dart';
import 'package:rentalhub/features/owner/presentation/widgets/finance/finance_summary_cards.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
  double textScale = 1.0,
}) async {
  await TestHarness.pumpScreenWithOverflowCheck(
    tester: tester,
    screen: screen,
    width: 360,
    height: 800,
    textScale: textScale,
    theme: theme ?? AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  group('AC-2 — auth stepper copies the onboarding-stepper colours', () {
    testWidgets('dark mode: current label is readable, done/current circles use the strong tokens',
        (tester) async {
      await _pump(
        tester,
        const Scaffold(body: AuthStepperBar(currentStep: 2)),
        theme: AppTheme.darkTheme,
      );
      // Done step 1: accentSuccessStrong circle (white check 5.48:1).
      expect(
        find.byWidgetPredicate((w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color ==
                AppColors.accentSuccessStrong),
        findsOneWidget,
      );
      // Current step 2: orangeFill circle (white icon 5.18:1).
      expect(
        find.byWidgetPredicate((w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color ==
                AppColors.orangeFill),
        findsOneWidget,
      );
      // Current label: pale lavender primaryContainer in dark mode —
      // the old navy #1B1E5C was 1.18:1 on the dark surface.
      expect(tester.widget<Text>(find.text('2. Select Role')).style?.color,
          AppColors.primaryContainer);
      // Done label: theme onSurfaceVariant, not the old navy.
      expect(tester.widget<Text>(find.text('1. Profile Info')).style?.color,
          AppColors.onSurfaceVariantDark);
      // Urdu labels get 2 lines, like the onboarding stepper.
      expect(tester.widget<Text>(find.text('2. Select Role')).maxLines, 2);
    });

    testWidgets('light mode: current label uses the theme primary',
        (tester) async {
      await _pump(
        tester,
        const Scaffold(body: AuthStepperBar(currentStep: 1)),
        theme: AppTheme.lightTheme,
      );
      expect(tester.widget<Text>(find.text('1. Profile Info')).style?.color,
          AppColors.primary);
    });
  });

  group('AC-7 — WhatsApp log tile readable colours + 48 dp Resend', () {
    Future<void> pumpTile(
      WidgetTester tester, {
      required String status,
    }) async {
      // Short strings: the test font renders ~1.85x wider than Inter,
      // so a full name + phone + the 9-char DELIVERED label overflows
      // the 360 px tile in the test env (a test artifact — on device
      // the same tile measures ~255 px wide). The colours and the
      // Resend target are what this test asserts.
      await _pump(
        tester,
        Scaffold(
          body: WhatsAppLogTile(
            recipientName: 'Ali',
            phone: '0300-123',
            messageType: 'Booked',
            timestamp: '10:30',
            status: status,
            onResend: () {},
          ),
        ),
      );
    }

    testWidgets('delivered/read/failed labels use the readable tokens',
        (tester) async {
      await pumpTile(tester, status: 'delivered');
      expect(
          tester.widget<Text>(find.text('DELIVERED')).style?.color,
          AppColors.successTextFor(Brightness.light));
      expect(
          tester
              .widget<Icon>(find.byIcon(Icons.check_circle_rounded))
              .color,
          AppColors.successTextFor(Brightness.light));

      await pumpTile(tester, status: 'read');
      expect(tester.widget<Text>(find.text('READ')).style?.color,
          AppColors.primary);

      await pumpTile(tester, status: 'failed');
      expect(tester.widget<Text>(find.text('FAILED')).style?.color,
          AppColors.dangerTextFor(Brightness.light));
    });

    testWidgets('Resend is a 48 dp TextButton in the orange text token',
        (tester) async {
      await pumpTile(tester, status: 'failed');
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Resend'),
      );
      expect(button.style?.minimumSize?.resolve(<WidgetState>{}),
          const Size(0, 48));
      expect(tester.getSize(find.widgetWithText(TextButton, 'Resend')).height,
          greaterThanOrEqualTo(48));
      expect(tester.widget<Text>(find.text('Resend')).style?.color,
          AppColors.orangeTextFor(Brightness.light));
      // Brand icon: the readable success green, not #25D366 (1.98:1).
      expect(
          tester.widget<Icon>(find.byIcon(Icons.chat_bubble_rounded)).color,
          AppColors.successTextFor(Brightness.light));
    });
  });

  group('AC-6 — finance summary amounts use the readable tokens', () {
    testWidgets('earnings green / expenses red are the *TextFor tokens',
        (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: FinanceSummaryCards(earnings: 185000, expenses: 45000),
        ),
      );
      expect(tester.widget<Text>(find.text('Rs. 185,000')).style?.color,
          AppColors.successTextFor(Brightness.light));
      expect(tester.widget<Text>(find.text('Rs. 45,000')).style?.color,
          AppColors.dangerTextFor(Brightness.light));
      expect(find.text('Rs. 140,000'), findsOneWidget);
    });
  });

  group('AC-17 — signature pad Clear button is 48 dp', () {
    testWidgets('Clear keeps a 48 dp minimum hit area', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: SignaturePadWidget(
            // Short label: the test font renders ~1.85x wider than
            // Inter, so the full 'Customer signature' label plus the
            // Clear button overflows 360 px in the test env (a test
            // artifact — the button's width is unchanged by the 48 dp
            // minimum, which only adds height).
            signerLabel: 'Customer',
            signerName: 'Ali',
          ),
        ),
      );
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Clear'),
      );
      expect(button.style?.minimumSize?.resolve(<WidgetState>{}),
          const Size(0, 48));
      expect(tester.getSize(find.widgetWithText(TextButton, 'Clear')).height,
          greaterThanOrEqualTo(48));
    });
  });

  group('AC-15 / DS-8 — app bar + nav labels allow 2 lines', () {
    testWidgets('MinimalAppBar title and subtitle allow 2 lines',
        (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: MinimalAppBar(
            title: 'Add Customer — enter the customer details',
            subtitle: 'Step 1 of 4 — CNIC and personal information',
          ),
        ),
      );
      expect(
          tester
              .widget<Text>(find.text(
                  'Add Customer — enter the customer details'))
              .maxLines,
          2);
      expect(
          tester
              .widget<Text>(
                  find.text('Step 1 of 4 — CNIC and personal information'))
              .maxLines,
          2);
    });

    testWidgets('nav label is 1 line at default scale, 2 lines at large text scale',
        (tester) async {
      final items = [
        const ShellNavItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        const ShellNavItem(
            icon: Icon(Icons.book_rounded), label: 'Bookings'),
      ];
      await _pump(
        tester,
        Scaffold(
          bottomNavigationBar: AppShellNav(
            currentIndex: 0,
            onTap: (_) {},
            items: items,
          ),
          body: const SizedBox(),
        ),
        textScale: 1.0,
      );
      expect(tester.widget<Text>(find.text('Bookings')).maxLines, 1);

      await _pump(
        tester,
        Scaffold(
          bottomNavigationBar: AppShellNav(
            currentIndex: 0,
            onTap: (_) {},
            items: items,
          ),
          body: const SizedBox(),
        ),
        textScale: 2.0,
      );
      expect(tester.widget<Text>(find.text('Bookings')).maxLines, 2);
    });

    testWidgets('nav label fallback reads the labelSmall theme slot (DS-8)',
        (tester) async {
      // No navigationBarTheme labelTextStyle: the fallback must be
      // the 11 sp labelSmall slot, not a hardcoded 12 sp style.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true).copyWith(
            navigationBarTheme: const NavigationBarThemeData(),
          ),
          home: Scaffold(
            bottomNavigationBar: AppShellNav(
              currentIndex: 0,
              onTap: (_) {},
              items: const [
                ShellNavItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                ShellNavItem(
                    icon: Icon(Icons.book_rounded), label: 'Bookings'),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = tester.widget<Text>(find.text('Home'));
      expect(label.style?.fontSize, 11);
      expect(label.style?.color, Colors.white);
    });
  });

  group('AC-4 / AC-5 — admin 2FA badge + error text use readable tokens', () {
    testWidgets('2FA badge: success token when on, warning token when off',
        (tester) async {
      const onMember = AdminTeamMember(
        uid: 'uid-1',
        email: 'ops@rentalhub.pk',
        adminRole: 'operations',
        totpEnabled: true,
      );
      await _pump(
        tester,
        Scaffold(
          body: AdminTeamMemberTile(
            member: onMember,
            canManage: true,
            onResetTotp: () {},
            onRevoke: () {},
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('2FA on')).style?.color,
          AppColors.successTextFor(Brightness.light));

      const offMember = AdminTeamMember(
        uid: 'uid-2',
        email: 'ops2@rentalhub.pk',
        adminRole: 'operations',
        totpEnabled: false,
      );
      await _pump(
        tester,
        Scaffold(
          body: AdminTeamMemberTile(
            member: offMember,
            canManage: true,
            onResetTotp: () {},
            onRevoke: () {},
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('2FA off')).style?.color,
          AppColors.warningTextFor(Brightness.light));
    });

    testWidgets('login + TOTP error lines use the danger text token',
        (tester) async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      addTearDown(emailController.dispose);
      addTearDown(passwordController.dispose);
      await _pump(
        tester,
        Scaffold(
          body: AdminLoginForm(
            emailController: emailController,
            passwordController: passwordController,
            isWorking: false,
            error: 'Wrong email or password',
            onSignIn: () {},
          ),
        ),
      );
      expect(
          tester
              .widget<Text>(find.text('Wrong email or password'))
              .style
              ?.color,
          AppColors.dangerTextFor(Brightness.light));

      final codeController = TextEditingController();
      addTearDown(codeController.dispose);
      await _pump(
        tester,
        Scaffold(
          body: AdminTotpStep(
            codeController: codeController,
            isWorking: false,
            error: 'Wrong code',
            onVerify: () {},
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('Wrong code')).style?.color,
          AppColors.dangerTextFor(Brightness.light));
    });
  });

  group('AC-9 — admin KPI value uses the displayLarge slot', () {
    testWidgets('value renders at 28 sp (displayLarge), not 24 sp w700',
        (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: AdminKpiCard(
            title: 'Shops',
            value: '12',
            changeLabel: '+2 this month',
            icon: Icons.store_rounded,
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('12')).style?.fontSize, 28);
    });
  });

  group('AC-9 / DS-1 / AC-16 — source scans for the Team A files', () {
    String codeWithoutComments(String path) {
      // The AC-9 comments themselves name the old weights ("24 sp
      // w700") — strip line comments before scanning.
      return File(path)
          .readAsStringSync()
          .split('\n')
          .map((line) => line.split('//').first)
          .join('\n');
    }

    test('no off-scale w700/w800/w900/bold weight in the AC-9 files', () {
      const files = [
        'lib/features/customer/presentation/views/customer_saved_shops_view.dart',
        'lib/features/owner/presentation/views/owner_subscription_plan_detail_view.dart',
        'lib/features/admin/presentation/widgets/admin_kpi_card.dart',
      ];
      final bold = RegExp(r'FontWeight\.(w700|w800|w900|bold)\b');
      final hits = <String>[];
      for (final path in files) {
        final content = codeWithoutComments(path);
        if (bold.hasMatch(content)) hits.add(path);
      }
      expect(hits, isEmpty,
          reason: 'Off-scale weight survives in: ${hits.join(', ')}');
      // The two price/value slots moved to the sanctioned slot.
      expect(
          File('lib/features/owner/presentation/views/owner_subscription_plan_detail_view.dart')
              .readAsStringSync(),
          contains('displayLarge'));
      expect(
          File('lib/features/admin/presentation/widgets/admin_kpi_card.dart')
              .readAsStringSync(),
          contains('displayLarge'));
    });

    test('no per-file selectedColor/labelStyle overrides in the DS-1 files',
        () {
      const files = [
        'lib/features/owner/presentation/widgets/fleet/fleet_filter_chips.dart',
        'lib/features/discovery/presentation/views/shop_cars_view.dart',
        'lib/features/customer/presentation/widgets/dispute_category_chips.dart',
        'lib/features/owner/presentation/widgets/customer_list_filter_chips.dart',
        'lib/features/owner/presentation/views/owner_fare_table_view.dart',
        'lib/features/owner/presentation/widgets/finance/finance_hub_header.dart',
        'lib/features/customer/presentation/views/customer_bookings_view.dart',
      ];
      final hits = <String>[];
      for (final path in files) {
        final content = File(path).readAsStringSync();
        if (content.contains('selectedColor:') ||
            content.contains('labelStyle:')) {
          hits.add(path);
        }
      }
      expect(hits, isEmpty,
          reason:
              'Per-file chip overrides survive in: ${hits.join(', ')} — the theme chipTheme owns the selected spec.');
    });

    test('the three AC-16 slabs branch on brightness', () {
      const files = [
        'lib/features/customer/presentation/views/customer_reputation_view.dart',
        'lib/features/customer/presentation/widgets/dispute_form_fields.dart',
        'lib/features/owner/presentation/widgets/add_vehicle/vehicle_review_step_widget.dart',
      ];
      for (final path in files) {
        expect(File(path).readAsStringSync(),
            contains('primaryContainerOnDark'),
            reason: '$path still uses the pale primaryContainer slab');
      }
    });
  });
}
