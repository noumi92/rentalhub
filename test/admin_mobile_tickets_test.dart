import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_announcements_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_platform_settings_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_tickets_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/announcement_form_sheet.dart';
import 'package:rentalhub/features/admin/presentation/widgets/ticket_detail_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// Mobile-first adaptivity (2026-11-10): the ticket sheet's long
// quick-reply chips are a full-width wrapping column (a Wrap of
// intrinsic-width chips overflows at 360px); settings, announcements
// and tickets get compact padding. The unverified-shop toggles stay
// reachable on mobile.

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  double width = 360,
  double height = 800,
  double textScale = 1.35,
}) async {
  await TestHarness.pumpScreenWithOverflowCheck(
    tester: tester,
    screen: screen,
    width: width,
    height: height,
    textScale: textScale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('admin_mobile_tickets', () {
    testWidgets('tickets inbox at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminTicketsView());
      expect(find.text('Support tickets'), findsWidgets);
      expect(find.textContaining('No tickets'), findsOneWidget);
    });

    testWidgets('tickets inbox at desktop width', (tester) async {
      await _pump(tester, const AdminTicketsView(),
          width: 1280, textScale: 1.0);
      expect(find.text('Support tickets'), findsWidgets);
    });

    testWidgets('ticket sheet with long quick replies at 360px',
        (tester) async {
      final ticket = SupportTicket(
        id: 'T-1',
        customerId: 'customer-1',
        message: 'The showroom charged me extra for fuel.',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now(),
      );
      await _pump(
          tester,
          Scaffold(
            body: TicketDetailSheet(ticket: ticket, onChanged: () {}),
          ));
      expect(find.text('Ticket T-1'), findsOneWidget);
      expect(find.text('Send reply'), findsOneWidget);
      expect(find.text('Close ticket'), findsOneWidget);
      expect(find.text('Escalate'), findsOneWidget);
    });

    testWidgets('ticket sheet at 360px, 2.0x text', (tester) async {
      final ticket = SupportTicket(
        id: 'T-1',
        customerId: 'customer-1',
        message: 'The showroom charged me extra for fuel.',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now(),
      );
      await _pump(
          tester,
          Scaffold(
            body: TicketDetailSheet(ticket: ticket, onChanged: () {}),
          ),
          textScale: 2.0);
      expect(find.text('Close ticket'), findsOneWidget);
    });
  });

  group('admin_mobile_settings_announcements', () {
    testWidgets('settings at 360px with unverified toggles reachable',
        (tester) async {
      await _pump(tester, const AdminPlatformSettingsView());
      expect(find.text('Cities & settings'), findsWidgets);
      expect(find.text('Display unverified shops'), findsOneWidget);
      expect(find.text('Allow bookings from unverified shops'),
          findsOneWidget);
      expect(find.text('Save settings'), findsOneWidget);
    });

    testWidgets('settings at desktop width', (tester) async {
      await _pump(tester, const AdminPlatformSettingsView(),
          width: 1280, textScale: 1.0);
      expect(find.text('Save settings'), findsOneWidget);
    });

    testWidgets('announcements at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminAnnouncementsView());
      expect(find.text('Announcements'), findsWidgets);
      expect(find.text('New announcement'), findsOneWidget);
    });

    testWidgets('announcement composer at 360px, 1.35x text',
        (tester) async {
      await _pump(
          tester,
          const Scaffold(
            body: AnnouncementFormSheet(onCreated: _noop),
          ));
      expect(find.text('New announcement'), findsOneWidget);
      expect(find.text('Save announcement'), findsOneWidget);
    });

    testWidgets('announcement composer at 360px, 2.0x text',
        (tester) async {
      await _pump(
          tester,
          const Scaffold(
            body: AnnouncementFormSheet(onCreated: _noop),
          ),
          textScale: 2.0);
      expect(find.text('Save announcement'), findsOneWidget);
    });
  });
}

void _noop() {}
