import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/utils/csv_escape.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_activity_log_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_customers_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_reports_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_tickets_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/customer_trust_breakdown.dart';
import 'package:rentalhub/features/admin/presentation/widgets/ticket_detail_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/l10n/app_localizations_en.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  AdminReport reportWith({Map<String, int> cities = const {'Lahore': 8}}) {
    return AdminReport(
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 31, 23, 59, 59, 999),
      totalBookings: 12,
      completedBookings: 9,
      bookingRevenue: 450000,
      bookingsByCity: cities,
      topShops: const [MapEntry('Metro', 5)],
      financeIncome: 120000,
      financeExpense: 40000,
      incomeByCategory: const {'rent': 120000},
      expenseByCategory: const {'fuel': 40000},
      newCustomers: 6,
      disputesOpen: 1,
      disputesResolved: 2,
    );
  }

  group('F-m10 — CSV escaping (RFC 4180)', () {
    test('plain values are untouched, commas/quotes/newlines quote', () {
      expect(csvEscape('Lahore'), 'Lahore');
      expect(csvEscape('Shop, Main'), '"Shop, Main"');
      expect(csvEscape('Say "hi"'), '"Say ""hi"""');
      expect(csvEscape('line1\nline2'), '"line1\nline2"');
      expect(csvRow(['a', 'b,c', 'd"e']), 'a,"b,c","d""e"');
    });

    test('report CSV escapes a city and a shop with a comma', () {
      final csv = AdminSupportDataSource.reportCsv(
        reportWith(cities: const {'Lahore, Cantt': 3}),
      );
      expect(csv, contains('"Lahore, Cantt",3'));
      expect(csv, contains('Total bookings,12'));
    });

    test('audit-log CSV keeps a quoted detail verbatim', () {
      final csv = AdminRemoteDataSource.auditLogsCsv([
        AuditLogEntry.fromMap('log-1', {
          'type': 'admin_action',
          'action': 'shop_application_rejected',
          'actor_email': 'admin@rentalhub.pk',
          'target_type': 'shop',
          'target_id': 'shop-1',
          'detail': 'Reason: "late", see note\nsecond line',
          'created_at': '2026-11-06T10:00:00.000Z',
        }),
      ]);
      expect(csv, contains('"Reason: ""late"", see note\nsecond line"'));
    });
  });

  group('F-M17 — report range is inclusive of the To day', () {
    test('inclusiveTo is the end of the picked day', () {
      final end = AdminSupportDataSource.inclusiveTo(DateTime(2026, 11, 14));
      expect(end, DateTime(2026, 11, 14, 23, 59, 59, 999));
    });
  });

  group('F-m12 — report PDF summary', () {
    test('reportPdf returns a real PDF document', () async {
      final bytes =
          await AdminSupportDataSource.reportPdf(reportWith());
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('F-m15 — ticket SLA shows minutes under an hour', () {
    test('30 minutes left reads in minutes, not 0h', () {
      // Filed 29 minutes ago: 31 minutes of the 1h SLA remain minus
      // the milliseconds since construction, so `inMinutes` is a
      // stable 30. Filing exactly 30 minutes ago would read 29m
      // (truncation), which is correct behaviour, not a bug.
      final ticket = SupportTicket(
        id: 'T-1',
        customerId: 'customer-1',
        message: 'Help',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now().subtract(const Duration(minutes: 29)),
      );
      expect(ticket.slaText(), '30m of 1h SLA left');
    });

    test('breached by 30 minutes reads in minutes, not 0h', () {
      final ticket = SupportTicket(
        id: 'T-2',
        customerId: 'customer-1',
        message: 'Help',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 30),
        ),
      );
      expect(ticket.slaText(), 'SLA breached by 30m');
    });

    test('breached by hours still reads in hours', () {
      final ticket = SupportTicket(
        id: 'T-3',
        customerId: 'customer-1',
        message: 'Help',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(ticket.slaText(), contains('SLA breached'));
      expect(ticket.slaText(), contains('4h'));
    });

    test('localised form mirrors the minute branches', () {
      final l10n = AppLocalizationsEn();
      final ticket = SupportTicket(
        id: 'T-4',
        customerId: 'customer-1',
        message: 'Help',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now().subtract(const Duration(minutes: 29)),
      );
      expect(ticket.slaTextL10n(l10n), '30m of 1h SLA left');
    });
  });

  group('F-M19 — tickets link to shop and booking', () {
    test('fromMap reads camelCase and snake_case links', () {
      final a = SupportTicket.fromMap('T-1', {
        'customerId': 'customer-1',
        'message': 'Help',
        'status': 'open',
        'priority': 'medium',
        'shopId': 'shop-1',
        'bookingId': 'booking-1',
        'createdAt': DateTime.now().toIso8601String(),
      });
      expect(a.shopId, 'shop-1');
      expect(a.bookingId, 'booking-1');
      final b = SupportTicket.fromMap('T-2', {
        'customerId': 'customer-1',
        'message': 'Help',
        'status': 'open',
        'shop_id': 'shop-2',
        'booking_id': 'booking-2',
      });
      expect(b.shopId, 'shop-2');
      expect(b.bookingId, 'booking-2');
    });

    test('tickets without a link parse with null links', () {
      final t = SupportTicket.fromMap('T-3', {
        'customerId': 'customer-1',
        'message': 'Help',
        'status': 'open',
      });
      expect(t.shopId, isNull);
      expect(t.bookingId, isNull);
    });
  });

  group('F-m1 / F-m2 / F-m3 — paged reads are empty offline', () {
    test('ticket, audit-log and customer pages are empty offline',
        () async {
      final support = AdminSupportDataSource();
      final ticketsPage = await support.getTicketsPage();
      expect(ticketsPage.items, isEmpty);
      expect(ticketsPage.hasMore, isFalse);
      expect(await support.searchTickets('anything'), isEmpty);

      final remote = AdminRemoteDataSource();
      final logsPage = await remote.getAuditLogsPage();
      expect(logsPage.items, isEmpty);
      expect(logsPage.hasMore, isFalse);
      expect(
        await remote.getAuditLogsFiltered(actionPrefix: 'support_ticket'),
        isEmpty,
      );
      expect(
        await remote.countAuditLogsFiltered(actionPrefix: 'support_ticket'),
        0,
      );
      final stats = await remote.getPlatformStats();
      expect(stats.pendingShopCount, 0);

      final people = AdminPeopleDataSource();
      final customersPage = await people.getCustomersPage();
      expect(customersPage.items, isEmpty);
      expect(customersPage.hasMore, isFalse);
      expect(await people.searchCustomers('ahmed'), isEmpty);

      final shops = AdminShopsDataSource();
      expect(await shops.getShopCreditsBalance('shop-1'), isNull);
    });
  });

  group('AD-m18 / AD-M9 — trust breakdown labels', () {
    const breakdown = TrustScoreBreakdown(
      base: 2.5,
      kyc: 1.0,
      trips: 0.5,
      ratings: 0.0,
      punctuality: 0.0,
      conduct: 0.0,
      total: 4.0,
    );

    // Phase 4 (4.4b) — live-score-only: the stored score is
    // never shown, even when it would have disagreed with the
    // live score (the old tests asserted the "Previously stored"
    // comparison line).
    testWidgets('the stored score is never shown (live score only)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomerTrustBreakdown(
            breakdown: breakdown,
            completedTrips: 3,
            meanOwnerRating: null,
            kycStatus: 'verified',
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Previously stored'), findsNothing);
      expect(find.textContaining('Stored trust'), findsNothing);
      expect(find.text('4.0 / 5.0'), findsOneWidget);
      expect(find.textContaining('KYC verified'), findsOneWidget);
    });
  });

  group('Admin audit fix batch — views render', () {
    testWidgets('reports view shows the PDF export button',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminReportsView()));
      await tester.pumpAndSettle();
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
    });

    testWidgets('tickets view shows search and its empty state',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminTicketsView()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Search by message'), findsOneWidget);
      expect(find.textContaining('No tickets'), findsOneWidget);
    });

    testWidgets('customers view shows the CNIC filter chips',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminCustomersView()));
      await tester.pumpAndSettle();
      expect(find.text('CNIC on file'), findsOneWidget);
      expect(find.text('CNIC missing'), findsOneWidget);
      expect(find.textContaining('No customers match'), findsOneWidget);
    });

    testWidgets('dashboard shows the pending-approvals card',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminDashboardView()));
      await tester.pumpAndSettle();
      expect(find.text('Shops waiting for approval'), findsOneWidget);
      expect(find.textContaining('Pending'), findsWidgets);
    });

    testWidgets('activity log shows the filter controls',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminActivityLogView()));
      await tester.pumpAndSettle();
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Admin email'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
      expect(find.textContaining('No audit entries yet'), findsOneWidget);
    });

    testWidgets('ticket sheet shows linked shop and booking chips',
        (tester) async {
      final ticket = SupportTicket(
        id: 'T-1',
        customerId: 'customer-1',
        message: 'The showroom charged me extra for fuel.',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now(),
        shopId: 'shop-1',
        bookingId: 'booking-1',
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TicketDetailSheet(ticket: ticket, onChanged: () {}),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Shop:'), findsOneWidget);
      expect(find.textContaining('Booking:'), findsOneWidget);
      expect(find.textContaining('update you here'), findsOneWidget);
      expect(find.textContaining('WhatsApp'), findsNothing);
    });
  });
}
