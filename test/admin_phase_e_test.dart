import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_announcements_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_platform_settings_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_reports_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_tickets_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/ticket_detail_sheet.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Phase E (E1) — ticket SLA', () {
    test('high is 1 h, medium 4 h, low 24 h', () {
      expect(
        SupportTicket(
          id: 'T-1',
          customerId: 'customer-1',
          message: 'Help',
          status: 'open',
          priority: 'high',
          createdAt: DateTime.now(),
        ).slaHours,
        1,
      );
      expect(
        SupportTicket(
          id: 'T-2',
          customerId: 'customer-1',
          message: 'Help',
          status: 'open',
          priority: 'medium',
          createdAt: DateTime.now(),
        ).slaHours,
        4,
      );
      expect(
        SupportTicket(
          id: 'T-3',
          customerId: 'customer-1',
          message: 'Help',
          status: 'open',
          priority: 'low',
          createdAt: DateTime.now(),
        ).slaHours,
        24,
      );
    });

    test('an old ticket reports its breach', () {
      final ticket = SupportTicket(
        id: 'T-4',
        customerId: 'customer-1',
        message: 'Help',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(ticket.slaText(), contains('SLA breached'));
    });

    test('a ticket without a priority defaults to medium', () {
      final ticket = SupportTicket.fromMap('T-5', {
        'customerId': 'customer-1',
        'message': 'Help',
        'status': 'open',
        'createdAt': DateTime.now().toIso8601String(),
      });
      expect(ticket.priority, 'medium');
      expect(ticket.slaHours, 4);
    });
  });

  group('Phase E (E2/E3/E4) — settings, announcements, reports', () {
    test('platform settings default and round-trip', () {
      const settings = PlatformSettings();
      expect(settings.liveCities, contains('Lahore'));
      expect(settings.advancePercent, 30);
      expect(settings.defaultDepositPkr, 10000);
      final restored = PlatformSettings.fromMap(settings.toMap());
      expect(restored.advancePercent, 30);
      expect(restored.maintenanceMode, isFalse);
    });

    test('announcement parses with zero stats', () {
      final a = AdminAnnouncement.fromMap('ANN-1', {
        'title_en': 'Eid offer',
        'title_ur': 'عید آفر',
        'body_en': 'Drive more this Eid.',
        'body_ur': 'اس عید زیادہ چلائیں۔',
        'audience_role': 'all',
        'channel': 'push',
        'status': 'draft',
      });
      expect(a.titleEn, 'Eid offer');
      expect(a.titleUr, 'عید آفر');
      expect(a.sent, 0);
      expect(a.delivered, 0);
      expect(a.opened, 0);
    });

    test('report CSV has the header and KPI rows', () {
      final report = AdminReport(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
        totalBookings: 12,
        completedBookings: 9,
        bookingRevenue: 450000,
        bookingsByCity: {'Lahore': 8, 'Karachi': 4},
        topShops: const [MapEntry('Metro', 5)],
        financeIncome: 120000,
        financeExpense: 40000,
        incomeByCategory: const {'rent': 120000},
        expenseByCategory: const {'fuel': 40000},
        newCustomers: 6,
        disputesOpen: 1,
        disputesResolved: 2,
      );
      final csv = AdminSupportDataSource.reportCsv(report);
      expect(csv, contains('Total bookings,12'));
      expect(csv, contains('Booking revenue (Rs.),450000'));
      expect(csv, contains('Lahore,8'));
      expect(csv, contains('Metro,5'));
    });
  });

  group('Phase E — support data layer (offline)', () {
    test('reads are empty/default and writes fail honestly offline', () async {
      final ds = AdminSupportDataSource();
      expect(await ds.getTickets(), isEmpty);
      expect(await ds.getTicketReplies('T-1'), isEmpty);
      expect(await ds.getTicketNotes('T-1'), isEmpty);
      expect(await ds.getAnnouncements(), isEmpty);
      expect(await ds.getReport(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
      ), isNull);
      expect((await ds.getPlatformSettings()).advancePercent, 30);
      expect(
        await ds.createAnnouncement(
          titleEn: 't',
          titleUr: 't',
          bodyEn: 'b',
          bodyUr: 'b',
          audienceRole: 'all',
          audienceCity: 'all',
          audiencePlan: 'all',
          channel: 'push',
        ),
        isNull,
      );
      expect(
        await ds.sendAnnouncement(announcementId: 'ANN-1'),
        isNull,
      );
      expect(
        await ds.replyToTicket(ticketId: 'T-1', text: 'hi'),
        isFalse,
      );
      expect(
        await ds.setTicketStatus(ticketId: 'T-1', status: 'closed'),
        isFalse,
      );
      expect(
        await ds.savePlatformSettings(const PlatformSettings()),
        isFalse,
      );
    });
  });

  group('Phase E — views render', () {
    testWidgets('tickets inbox shows its empty state', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminTicketsView()));
      await tester.pumpAndSettle();
      expect(find.text('Support tickets'), findsWidgets);
      expect(find.textContaining('No tickets'), findsOneWidget);
    });

    testWidgets('platform settings view shows the defaults',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminPlatformSettingsView()));
      await tester.pumpAndSettle();
      expect(find.text('Cities & settings'), findsWidgets);
      expect(find.text('Save settings'), findsOneWidget);
    });

    testWidgets('announcements view shows the composer button',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminAnnouncementsView()));
      await tester.pumpAndSettle();
      expect(find.text('Announcements'), findsWidgets);
      expect(find.text('New announcement'), findsOneWidget);
      expect(find.textContaining('No announcements yet'), findsOneWidget);
    });

    testWidgets('reports view shows the range and export', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AdminReportsView()));
      await tester.pumpAndSettle();
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.textContaining('No data for this range'), findsOneWidget);
    });

    testWidgets('ticket sheet shows the message and actions',
        (tester) async {
      final ticket = SupportTicket(
        id: 'T-1',
        customerId: 'customer-1',
        message: 'The showroom charged me extra for fuel.',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TicketDetailSheet(ticket: ticket, onChanged: () {}),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Ticket T-1'), findsOneWidget);
      expect(
          find.text('The showroom charged me extra for fuel.'),
          findsOneWidget);
      expect(find.text('Send reply'), findsOneWidget);
      expect(find.text('Close ticket'), findsOneWidget);
      expect(find.text('Escalate'), findsOneWidget);
    });
  });
}
