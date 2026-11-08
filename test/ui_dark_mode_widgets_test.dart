// Dark-mode widget tests on REAL screens and widgets.
//
// The audit (rentalhub-dark-nav-audit.md) found that
// test/ui_dark_mode_test.dart only asserted token values and never rendered
// a view in dark mode — which is why Phase A passed while the views stayed
// broken (navy text on dark surfaces, white cards, invisible dropdowns).
// These tests pump the fixed widgets and the tab screens in the real dark
// theme and assert:
//   - no pure-white surface is painted anywhere (except the deliberate
//     near-white keeps: the QR pass card and the Pakistani plate, skipped
//     by ancestor and asserted separately), and
//   - text that used to carry a hardcoded light token now resolves to a
//     readable colour — asserted as WCAG contrast against the surface it
//     sits on (AA 4.5:1), not as an exact token, because the theme
//     deliberately uses onSurfaceVariant for secondary text.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/pakistani_plate_widget.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/digital_qr_pass_widget.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_bookings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';
import 'package:rentalhub/features/customer/presentation/widgets/booking_ticket_card.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_kpis.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_ledger_item.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/revenue_kpi_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/request_triage_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

BookingEntity _seededBooking({String status = 'payment_submitted'}) =>
    BookingEntity(
      bookingId: 'RH-1762574400123-0042',
      customerId: 'cust-101',
      shopId: 'shop-1',
      vehicleId: 'v-1',
      packageType: '24h',
      pickupTime: DateTime(2026, 11, 8, 10),
      returnTime: DateTime(2026, 11, 9, 10),
      totalAmount: 125000,
      remainingBalance: 125000,
      status: status,
      vehicleName: 'Toyota Corolla Grande 1.8',
      vehiclePlate: 'LEA-21-4820',
      shopName: 'Al-Madina Rent a Car',
      customerName: 'Muhammad Ahmed Khan Butt',
      customerPhone: '0300-1234567',
    );

/// Painted pure-white surfaces in the pumped tree. The deliberate
/// near-white keeps (the QR pass card, the Pakistani plate) are skipped by
/// ancestor — their text is asserted separately, in the QR pass test.
List<String> _whiteSurfaces(WidgetTester tester) {
  final offenders = <String>[];

  bool isKeep(Element el) =>
      el.findAncestorWidgetOfExactType<DigitalQrPassWidget>() != null ||
      el.findAncestorWidgetOfExactType<PakistaniPlateWidget>() != null;

  void check(Element el, Color? color, String kind) {
    if (color != Colors.white || isKeep(el)) return;
    offenders.add('$kind (${el.widget.runtimeType})');
  }

  for (final el in find.byType(Container).evaluate()) {
    final w = el.widget as Container;
    final d = w.decoration;
    check(el, w.color ?? (d is BoxDecoration ? d.color : null), 'Container');
  }
  for (final el in find.byType(Card).evaluate()) {
    check(el, (el.widget as Card).color, 'Card');
  }
  for (final el in find.byType(Material).evaluate()) {
    check(el, (el.widget as Material).color, 'Material');
  }
  for (final el in find.byType(DecoratedBox).evaluate()) {
    final d = (el.widget as DecoratedBox).decoration;
    check(el, d is BoxDecoration ? d.color : null, 'DecoratedBox');
  }
  return offenders;
}

/// The resolved colour of the (single) Text rendering [text].
Color? _textColor(WidgetTester tester, String text) {
  final matches = find.text(text).evaluate().toList();
  expect(matches, hasLength(1), reason: 'expected exactly one "$text"');
  return (matches.first.widget as Text).style?.color;
}

double _relativeLuminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio between [foreground] text and its [background].
double _contrastRatio(Color foreground, Color background) {
  final l1 = _relativeLuminance(foreground);
  final l2 = _relativeLuminance(background);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

/// The text rendering [text] must be readable on [background] (WCAG AA
/// 4.5:1) and must not be the brand navy that was invisible in dark mode.
void _expectReadable(
    WidgetTester tester, String text, Color background) {
  final color = _textColor(tester, text);
  expect(color, isNotNull, reason: '"$text" has no resolved colour');
  expect(color, isNot(AppColors.primary),
      reason: '"$text" is still the brand navy in dark mode');
  expect(_contrastRatio(color!, background), greaterThanOrEqualTo(4.5),
      reason: '"$text" is $color on $background');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  final darkOnSurface = AppTheme.darkTheme.colorScheme.onSurface;

  group('Dark mode on the fixed widgets (seeded, realistic data)', () {
    testWidgets('RevenueKpiCard: 7-digit amount stays readable in dark',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const RevenueKpiCard(
          title: 'Completed Trips',
          amount: 'Rs. 1234567',
          changeLabel: '87% deposits settled',
          icon: Icons.task_alt_rounded,
        ),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      final surface = AppTheme.darkTheme.colorScheme.surface;
      _expectReadable(tester, 'Rs. 1234567', surface);
      _expectReadable(tester, 'Completed Trips', surface);
    });

    testWidgets('DashboardKpis: seeded 7-digit revenue, no white surfaces',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const DashboardKpis(
          totalRevenue: 1234567,
          growthLabel: '+12% vs last month',
          activeCount: 87,
          completedCount: 1234,
          settleLabel: '87% deposits settled',
          waitingCount: 42,
          fleetAvailable: 18,
          fleetTotal: 24,
        ),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      expect(_textColor(tester, 'Rs. 1234567'), darkOnSurface);
      // The change label is green in both modes; dark mode must use the
      // lighter success text token, not the light-mode green.
      expect(_textColor(tester, '87% deposits settled'),
          AppColors.successTextFor(Brightness.dark));
    });

    testWidgets('DashboardLedgerItem: long id + name, 6-digit amount',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const DashboardLedgerItem(
          bookingId: 'RH-1762574400123-0042',
          vehicleName: 'Toyota Corolla Grande 1.8',
          customerName: 'Muhammad Ahmed Khan Butt',
          amount: 125000,
          status: 'active',
        ),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      expect(_textColor(tester, 'Rs. 125000'), darkOnSurface);
      expect(_textColor(tester, 'Toyota Corolla Grande 1.8'), darkOnSurface);
      // The status chip for an active booking uses the dark primary
      // (light navy), never the brand navy. The label is the localized
      // 'Active', not the old uppercased status code.
      expect(_textColor(tester, 'Active'), AppColors.primaryOnDark);
    });

    testWidgets('RequestTriageCard: long vehicle + 6-digit amount',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: RequestTriageCard(
          booking: _seededBooking(),
          onApprove: () {},
          onReject: () {},
          onVerifyProof: () {},
        ),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      expect(_textColor(tester, 'Toyota Corolla Grande 1.8'), darkOnSurface);
      // The amount is the brand orange by design (readable on dark at
      // ~5.5:1); it was never navy, so it stays orange.
      expect(_textColor(tester, 'Rs. 125000'), AppColors.secondary);
      expect(
          _textColor(tester, 'Muhammad Ahmed Khan Butt'), darkOnSurface);
    });

    testWidgets('BookingTicketCard: requested status pill is not navy',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: BookingTicketCard(
          booking: _seededBooking(status: 'requested'),
          onTap: () {},
        ),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      expect(_textColor(tester, 'Toyota Corolla Grande 1.8'), darkOnSurface);
      expect(_textColor(tester, 'Total: Rs. 125000'), darkOnSurface);
      // 'requested' maps to the warning branch — the light amber in dark
      // mode — not the default (navy) branch.
      expect(_textColor(tester, 'REQUESTED'),
          AppColors.warningTextFor(Brightness.dark));
    });

    testWidgets('BookingTicketCard: unknown status falls back to light navy',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: BookingTicketCard(
          booking: _seededBooking(status: 'active'),
          onTap: () {},
        ),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      // 'active' hits the default branch: the light navy in dark mode,
      // never the brand navy.
      expect(_textColor(tester, 'ACTIVE'), AppColors.primaryOnDark);
    });

    testWidgets('BookingTicketCard: paid status pill uses the light green',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: BookingTicketCard(
          booking: _seededBooking(status: 'paid'),
          onTap: () {},
        ),
        theme: AppTheme.darkTheme,
      );
      expect(_textColor(tester, 'PAID'),
          AppColors.successTextFor(Brightness.dark));
    });

    testWidgets(
        'DigitalQrPassWidget: the white card is a keep, but its text is dark ink',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: DigitalQrPassWidget(
          bookingId: 'RH-1762574400123-0042',
          vehicleName: 'Toyota Corolla Grande 1.8',
          plateNumber: 'LEA-21-4820',
          shopName: 'Al-Madina Rent a Car',
          pickupTime: DateTime(2026, 11, 8, 10, 30),
        ),
        theme: AppTheme.darkTheme,
      );
      // The pass itself stays white on purpose (scannable, printable).
      expect(
        find.byWidgetPredicate((w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color == Colors.white),
        findsWidgets,
      );
      // ...but every line of text on it must be dark ink, not theme text
      // (which is near-white in dark mode and invisible on the pass).
      final texts = find
          .descendant(
            of: find.byType(DigitalQrPassWidget),
            matching: find.byType(Text),
          )
          .evaluate()
          .toList();
      expect(texts, isNotEmpty);
      for (final el in texts) {
        if (el.findAncestorWidgetOfExactType<PakistaniPlateWidget>() !=
            null) {
          continue; // the plate is its own deliberate keep.
        }
        final color = (el.widget as Text).style?.color;
        expect(
          color,
          anyOf(AppColors.textPrimary, AppColors.textMuted),
          reason: 'QR pass text "${(el.widget as Text).data}" has colour '
              '$color in dark mode — invisible on the white pass.',
        );
      }
      expect(
        tester.widget<Icon>(find.byIcon(Icons.qr_code_2_rounded)).color,
        AppColors.textPrimary,
      );
    });
  });

  group('Dark mode on the tab screens (empty state)', () {
    testWidgets('CustomerWalletView has no white surface in dark',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerWalletView(),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      expect(find.text('Wallet & Security Escrow'), findsOneWidget);
    });

    testWidgets('OwnerFleetView has no white surface in dark',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerFleetView(),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      expect(find.text('Fleet Management'), findsOneWidget);
    });

    testWidgets('CustomerBookingsView has no white surface in dark',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerBookingsView(),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      expect(find.text('My Reservations'), findsOneWidget);
    });

    testWidgets('OwnerDashboardView has no white surface in dark',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerDashboardView(),
        theme: AppTheme.darkTheme,
      );
      expect(_whiteSurfaces(tester), isEmpty);
      expect(find.text('Showroom Revenue & Operations'), findsOneWidget);
    });
  });
}
