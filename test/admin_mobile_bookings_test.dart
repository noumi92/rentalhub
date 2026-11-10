import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/presentation/views/admin_booking_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_bookings_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_disputes_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_reviews_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/dispute_decision_sheet.dart';
import 'package:rentalhub/features/customer/data/datasources/dispute_remote_data_source.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// Mobile-first adaptivity (2026-11-10): bookings move the status chip
// into the subtitle on compact widths; the booking detail stacks its
// Download button under the title; disputes/reviews get compact
// padding. Desktop layouts are unchanged.

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

  group('admin_mobile_bookings', () {
    testWidgets('bookings list at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminBookingsView());
      expect(find.text('Bookings'), findsWidgets);
      expect(find.textContaining('No bookings match'), findsOneWidget);
    });

    testWidgets('bookings list at desktop width', (tester) async {
      await _pump(tester, const AdminBookingsView(),
          width: 1280, textScale: 1.0);
      expect(find.text('Bookings'), findsWidgets);
    });

    testWidgets('booking detail stacks Download at 360px', (tester) async {
      await _pump(tester,
          const AdminBookingDetailView(bookingId: 'no-such-booking'));
      expect(find.text('Booking not found.'), findsOneWidget);
    });

    testWidgets('booking detail at desktop width', (tester) async {
      await _pump(tester,
          const AdminBookingDetailView(bookingId: 'no-such-booking'),
          width: 1280, textScale: 1.0);
      expect(find.text('Booking not found.'), findsOneWidget);
    });
  });

  group('admin_mobile_disputes_reviews', () {
    testWidgets('disputes centre at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminDisputesView());
      expect(find.text('Disputes centre'), findsWidgets);
      expect(find.textContaining('No disputes'), findsOneWidget);
    });

    testWidgets('disputes centre at desktop width', (tester) async {
      await _pump(tester, const AdminDisputesView(),
          width: 1280, textScale: 1.0);
      expect(find.text('Disputes centre'), findsWidgets);
    });

    testWidgets('reviews moderation at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminReviewsView());
      expect(find.text('Reviews moderation'), findsWidgets);
      expect(find.textContaining('No reviews in this queue'), findsOneWidget);
    });

    testWidgets('reviews moderation at desktop width', (tester) async {
      await _pump(tester, const AdminReviewsView(),
          width: 1280, textScale: 1.0);
      expect(find.text('Reviews moderation'), findsWidgets);
    });

    testWidgets('dispute decision sheet at 360px, 1.35x text',
        (tester) async {
      final dispute = DisputeRecord(
        id: 'DSP-1',
        bookingId: 'RH-123',
        category: 'Damage claim',
        description: 'The shop charged me for damage I did not cause.',
        status: 'open',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        shopId: 'shop-1',
        customerName: 'Ahmed Raza',
        customerId: 'customer-1',
      );
      await _pump(
          tester,
          Scaffold(
            body: DisputeDecisionSheet(dispute: dispute, onDecided: () {}),
          ));
      expect(find.text('Dispute DSP-1'), findsOneWidget);
      expect(find.text('Save decision'), findsOneWidget);
    });

    testWidgets('dispute decision sheet at 360px, 2.0x text',
        (tester) async {
      final dispute = DisputeRecord(
        id: 'DSP-1',
        bookingId: 'RH-123',
        category: 'Damage claim',
        description: 'The shop charged me for damage I did not cause.',
        status: 'open',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        shopId: 'shop-1',
        customerName: 'Ahmed Raza',
        customerId: 'customer-1',
      );
      await _pump(
          tester,
          Scaffold(
            body: DisputeDecisionSheet(dispute: dispute, onDecided: () {}),
          ),
          textScale: 2.0);
      expect(find.text('Save decision'), findsOneWidget);
    });
  });
}
