import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/data/datasources/admin_platform_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_booking_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_bookings_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_disputes_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_reviews_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/dispute_decision_sheet.dart';
import 'package:rentalhub/features/customer/data/datasources/dispute_remote_data_source.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Phase D (D3) — review auto-check signals', () {
    test('a 1-star review with no comment is a fake-review signal', () {
      final review = AdminReview.fromMap('rev-1', {
        'bookingId': 'RH-1',
        'shopId': 'shop-1',
        'customerId': 'customer-1',
        'shopRating': 1,
        'vehicleRating': 1,
        'customerComment': '',
      });
      expect(review.signals, contains('Fake review: 1-star with no comment'));
    });

    test('abusive wording is flagged', () {
      final review = AdminReview.fromMap('rev-2', {
        'bookingId': 'RH-1',
        'shopId': 'shop-1',
        'customerId': 'customer-1',
        'shopRating': 2,
        'vehicleRating': 2,
        'customerComment': 'Total scam, they stole my deposit.',
      });
      expect(review.signals, contains('Abusive / fake wording'));
    });

    test('a lopsided pair is a revenge signal', () {
      final review = AdminReview.fromMap('rev-3', {
        'bookingId': 'RH-1',
        'shopId': 'shop-1',
        'customerId': 'customer-1',
        'shopRating': 1,
        'vehicleRating': 1,
        'customerComment': 'The car was fine.',
        'punctualityRating': 5,
        'careRating': 5,
        'behaviorRating': 4,
      });
      expect(review.signals,
          contains('Revenge pattern: customer 1-star, owner 4+'));
    });

    test('a normal review has no signals', () {
      final review = AdminReview.fromMap('rev-4', {
        'bookingId': 'RH-1',
        'shopId': 'shop-1',
        'customerId': 'customer-1',
        'shopRating': 5,
        'vehicleRating': 4,
        'customerComment': 'Smooth trip, clean car.',
        'punctualityRating': 5,
        'careRating': 4,
        'behaviorRating': 5,
      });
      expect(review.signals, isEmpty);
      expect(review.moderationStatus, 'visible');
    });
  });

  group('Phase D — platform data layer (offline)', () {
    test('reads are empty and decisions fail honestly offline', () async {
      final ds = AdminPlatformDataSource();
      expect(await ds.getBookings(), isEmpty);
      expect(await ds.getBookingDetail('RH-1'), isNull);
      expect(await ds.getDisputes(), isEmpty);
      expect(await ds.getReviews(), isEmpty);
      expect(
        await ds.decideDispute(
          disputeId: 'DSP-1',
          decision: 'partial',
          decisionAmount: 1000,
          adminNote: 'test',
        ),
        isFalse,
      );
      expect(
        await ds.setReviewModeration(
            reviewId: 'rev-1', status: 'hidden', reason: 'test'),
        isFalse,
      );
    });
  });

  group('Phase D — views render', () {
    testWidgets('bookings list shows status filters and empty state',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AdminBookingsView()));
      await tester.pumpAndSettle();
      expect(find.text('Bookings'), findsWidgets);
      expect(find.text('requested'), findsOneWidget);
      expect(find.text('cancelled'), findsOneWidget);
      expect(find.textContaining('No bookings match'), findsOneWidget);
    });

    testWidgets('booking detail says not found for an unknown booking',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminBookingDetailView(bookingId: 'no-such-booking')));
      await tester.pumpAndSettle();
      expect(find.text('Booking not found.'), findsOneWidget);
    });

    testWidgets('disputes centre shows its empty state', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminDisputesView()));
      await tester.pumpAndSettle();
      expect(find.text('Disputes centre'), findsWidgets);
      expect(find.textContaining('No disputes'), findsOneWidget);
    });

    testWidgets('reviews view shows the queues and empty state',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AdminReviewsView()));
      await tester.pumpAndSettle();
      expect(find.text('Reviews moderation'), findsWidgets);
      expect(find.text('Abusive'), findsOneWidget);
      expect(find.text('Revenge'), findsOneWidget);
      expect(find.textContaining('No reviews in this queue'), findsOneWidget);
    });

    testWidgets('dispute decision sheet shows both sides and the SLA',
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
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DisputeDecisionSheet(
            dispute: dispute,
            onDecided: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dispute DSP-1'), findsOneWidget);
      expect(find.textContaining('Customer statement'), findsOneWidget);
      expect(find.textContaining('Shop side'), findsOneWidget);
      expect(find.textContaining('SLA:'), findsOneWidget);
      expect(find.text('Save decision'), findsOneWidget);
    });
  });
}
