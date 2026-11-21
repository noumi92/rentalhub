import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/booking_status_chip.dart';
import 'package:rentalhub/features/bookings/utils/booking_next_step.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_booking_detail_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_bookings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_dispute_view.dart';
import 'package:rentalhub/features/customer/presentation/widgets/booking_detail_actions.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/l10n/app_localizations_en.dart';

// Next-step batch (2026-11-21), Worker C: the customer next-step
// button on card and detail, the Disputed chip, the status-chip
// labels, and the navigate-back contract for the dispute submit.
//
// Card and detail both render from [resolveCustomerNextStep], so
// these tests pin the resolver's customer mapping through the
// widgets the customer actually sees — not just the resolver.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  tearDown(() {
    SignedInUser.override = null;
  });

  Widget appFor(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  BookingEntity sampleBooking({
    required String id,
    required String status,
    int advanceRequired = 2500,
  }) =>
      BookingEntity(
        bookingId: id,
        customerId: 'cust-nextstep',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        remainingBalance: 6500,
        advanceRequired: advanceRequired,
        status: status,
        vehicleName: 'Honda Civic',
      );

  void signInAs(String uid) {
    SignedInUser.override = SignedInUserData(
      uid: uid,
      displayName: 'Next Step',
      phoneNumber: '03001234567',
    );
  }

  Future<void> seedBooking(
    BookingRemoteDataSource ds,
    String uid,
    String vehicleName,
    String status,
  ) async {
    final created = await ds.createBookingRequest(
      customerId: uid,
      shopId: 'shop-1',
      vehicleId: 'veh-ns-${vehicleName.replaceAll(' ', '-')}',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: DateTime.now().add(const Duration(hours: 5)),
      returnTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
      totalAmount: 9000,
      advanceRequired: 2500,
      vehicleName: vehicleName,
    );
    if (status != 'requested') {
      await ds.updateBookingStatus(bookingId: created.bookingId, status: status);
    }
  }

  group('resolver: customer destinations and labels', () {
    test('active goes to the trip route, disputed to the disputes screen', () {
      final active = sampleBooking(id: 'B-act', status: 'active');
      expect(resolveCustomerNextStep(active).destination(active),
          '/customer/active/B-act');
      final disputed = sampleBooking(id: 'B-dis', status: 'disputed');
      expect(resolveCustomerNextStep(disputed).destination(disputed),
          '/customer/disputes');
      final paid = sampleBooking(id: 'B-paid', status: 'paid');
      expect(resolveCustomerNextStep(paid).destination(paid),
          '/customer/pass/B-paid');
    });

    test('labels are View Active Trip and Track Dispute', () {
      final l10n = AppLocalizationsEn();
      final active = sampleBooking(id: 'B-act', status: 'active');
      expect(resolveCustomerNextStep(active).label(l10n, active),
          'View Active Trip');
      final disputed = sampleBooking(id: 'B-dis', status: 'disputed');
      expect(resolveCustomerNextStep(disputed).label(l10n, disputed),
          'Track Dispute');
    });
  });

  group('BookingStatusChip.labelFor', () {
    test('disputed and requested have explicit labels', () {
      final l10n = AppLocalizationsEn();
      expect(BookingStatusChip.labelFor(l10n, 'disputed'), 'Disputed');
      expect(BookingStatusChip.labelFor(l10n, 'requested'), 'Pending Review');
    });
  });

  group('BookingDetailActions', () {
    testWidgets('requested shows the waiting line and Cancel, no primary',
        (tester) async {
      var cancelled = false;
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-req', status: 'requested'),
        onCancel: () => cancelled = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for approval'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);
      expect(find.text('Pay advance (Rs. 2,500)'), findsNothing);
      expect(find.text('View pickup pass'), findsNothing);

      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
    });

    testWidgets('approved shows Pay Advance plus Cancel', (tester) async {
      var paid = false;
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-app', status: 'approved'),
        onPayAdvance: () => paid = true,
        onCancel: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Pay advance (Rs. 2,500)'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);

      await tester.tap(find.text('Pay advance (Rs. 2,500)'));
      await tester.pumpAndSettle();
      expect(paid, isTrue);
    });

    testWidgets('payment_submitted shows no primary button', (tester) async {
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-sub', status: 'payment_submitted'),
        onViewPass: () {},
        onCancel: () {},
      )));
      await tester.pumpAndSettle();

      // No primary: the "Proof with shop" info lives in the detail
      // view, not in this widget, and there is no customer
      // proof-viewer route to offer.
      expect(find.byType(DebouncedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('View pickup pass'), findsNothing);
    });

    testWidgets('paid shows View pickup pass', (tester) async {
      var sawPass = false;
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-paid', status: 'paid'),
        onViewPass: () => sawPass = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('View pickup pass'), findsOneWidget);
      await tester.tap(find.text('View pickup pass'));
      await tester.pumpAndSettle();
      expect(sawPass, isTrue);
    });

    testWidgets('active shows View Active Trip, not View pickup pass',
        (tester) async {
      var sawTrip = false;
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-act', status: 'active'),
        onViewPass: () {},
        onViewActiveTrip: () => sawTrip = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('View Active Trip'), findsOneWidget);
      expect(find.text('View pickup pass'), findsNothing);
      await tester.tap(find.text('View Active Trip'));
      await tester.pumpAndSettle();
      expect(sawTrip, isTrue);
    });

    testWidgets('completed shows Rate This Trip plus File a Dispute',
        (tester) async {
      var rated = false;
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-done', status: 'completed'),
        onRateTrip: () => rated = true,
        onFileDispute: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Rate this trip'), findsOneWidget);
      expect(find.text('File a dispute'), findsOneWidget);
      await tester.tap(find.text('Rate this trip'));
      await tester.pumpAndSettle();
      expect(rated, isTrue);
    });

    testWidgets('disputed shows Track Dispute', (tester) async {
      var tracked = false;
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-dis', status: 'disputed'),
        onTrackDispute: () => tracked = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Track Dispute'), findsOneWidget);
      await tester.tap(find.text('Track Dispute'));
      await tester.pumpAndSettle();
      expect(tracked, isTrue);
    });

    testWidgets('cancelled shows File a Dispute, rejected Browse other shops',
        (tester) async {
      var filed = false;
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-can', status: 'cancelled'),
        onFileDispute: () => filed = true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('File a dispute'), findsOneWidget);
      expect(find.text('Rate this trip'), findsNothing);
      await tester.tap(find.text('File a dispute'));
      await tester.pumpAndSettle();
      expect(filed, isTrue);

      var browsed = false;
      await tester.pumpWidget(appFor(BookingDetailActions(
        booking: sampleBooking(id: 'B-rej', status: 'rejected'),
        onBrowseShops: () => browsed = true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Browse other shops'), findsOneWidget);
      await tester.tap(find.text('Browse other shops'));
      await tester.pumpAndSettle();
      expect(browsed, isTrue);
    });
  });

  group('CustomerBookingsView list card actions', () {
    testWidgets('paid card opens the pass directly, not the detail',
        (tester) async {
      const uid = 'cust-ns-paid';
      signInAs(uid);
      await seedBooking(
          di.sl<BookingRemoteDataSource>(), uid, 'Paid Passat', 'paid');
      var sawPass = false;
      var sawDetail = false;
      await tester.pumpWidget(appFor(CustomerBookingsView(
        onOpenBookingDetails: (_) => sawDetail = true,
        onViewPass: (_) => sawPass = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Paid Passat'), findsOneWidget);
      await tester.tap(find.text('View Pass'));
      await tester.pumpAndSettle();
      expect(sawPass, isTrue);
      expect(sawDetail, isFalse);
    });

    testWidgets('active card opens the trip', (tester) async {
      const uid = 'cust-ns-active';
      signInAs(uid);
      await seedBooking(
          di.sl<BookingRemoteDataSource>(), uid, 'Active Alto', 'active');
      var sawTrip = false;
      var sawDetail = false;
      await tester.pumpWidget(appFor(CustomerBookingsView(
        onOpenBookingDetails: (_) => sawDetail = true,
        onViewActiveTrip: (_) => sawTrip = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Active Alto'), findsOneWidget);
      await tester.tap(find.text('View Active Trip'));
      await tester.pumpAndSettle();
      expect(sawTrip, isTrue);
      expect(sawDetail, isFalse);
    });

    testWidgets('disputed card tracks the dispute', (tester) async {
      const uid = 'cust-ns-disputed';
      signInAs(uid);
      await seedBooking(
          di.sl<BookingRemoteDataSource>(), uid, 'Disputed Datsun', 'disputed');
      var tracked = false;
      await tester.pumpWidget(appFor(CustomerBookingsView(
        onTrackDispute: (_) => tracked = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Disputed Datsun'), findsOneWidget);
      await tester.tap(find.text('Track Dispute'));
      await tester.pumpAndSettle();
      expect(tracked, isTrue);
    });

    testWidgets('approved card pays the advance, completed card rates the trip',
        (tester) async {
      const uid = 'cust-ns-pay-rate';
      signInAs(uid);
      final ds = di.sl<BookingRemoteDataSource>();
      await seedBooking(ds, uid, 'Approved Aqua', 'approved');
      await seedBooking(ds, uid, 'Completed Corolla', 'completed');
      var paid = false;
      var rated = false;
      await tester.pumpWidget(appFor(CustomerBookingsView(
        onPayAdvance: (_) => paid = true,
        onRateTrip: (_) => rated = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pay Advance'));
      await tester.pumpAndSettle();
      expect(paid, isTrue);
      await tester.tap(find.text('Rate Trip'));
      await tester.pumpAndSettle();
      expect(rated, isTrue);
    });
  });

  group('CustomerBookingDetailView wiring', () {
    testWidgets('active detail calls onViewActiveTrip, disputed onTrackDispute',
        (tester) async {
      var sawTrip = false;
      await tester.pumpWidget(appFor(CustomerBookingDetailView(
        booking: sampleBooking(id: 'B-act', status: 'active'),
        onViewActiveTrip: () => sawTrip = true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('View Active Trip'), findsOneWidget);
      // The actions sit below the fold in the detail scroll view.
      await tester.ensureVisible(find.text('View Active Trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Active Trip'));
      await tester.pumpAndSettle();
      expect(sawTrip, isTrue);

      var tracked = false;
      await tester.pumpWidget(appFor(CustomerBookingDetailView(
        booking: sampleBooking(id: 'B-dis', status: 'disputed'),
        onTrackDispute: () => tracked = true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Track Dispute'), findsOneWidget);
      await tester.ensureVisible(find.text('Track Dispute'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Track Dispute'));
      await tester.pumpAndSettle();
      expect(tracked, isTrue);
    });
  });

  group('CustomerBookingsView initialTab', () {
    testWidgets('initialTab 4 opens on Disputed and filters to it',
        (tester) async {
      const uid = 'cust-ns-tab';
      signInAs(uid);
      final ds = di.sl<BookingRemoteDataSource>();
      await seedBooking(ds, uid, 'Tab Disputed', 'disputed');
      await seedBooking(ds, uid, 'Tab Completed', 'completed');

      await tester.pumpWidget(
          appFor(const CustomerBookingsView(initialTab: 4)));
      await tester.pumpAndSettle();

      expect(find.text('Tab Disputed'), findsOneWidget);
      expect(find.text('Tab Completed'), findsNothing);
      final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Disputed'));
      expect(chip.selected, isTrue);
    });

    testWidgets('default tab is All and shows every booking',
        (tester) async {
      const uid = 'cust-ns-tab-all';
      signInAs(uid);
      final ds = di.sl<BookingRemoteDataSource>();
      await seedBooking(ds, uid, 'All Disputed', 'disputed');
      await seedBooking(ds, uid, 'All Completed', 'completed');

      await tester.pumpWidget(appFor(const CustomerBookingsView()));
      await tester.pumpAndSettle();

      expect(find.text('All Disputed'), findsOneWidget);
      expect(find.text('All Completed'), findsOneWidget);
      final chip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'));
      expect(chip.selected, isTrue);
    });
  });

  group('navigate-back contract', () {
    testWidgets('dispute submit invokes onDisputeSubmitted',
        (tester) async {
      // The view delegates the post-submit navigation to the router
      // callback: the router must go to All Bookings
      // (RouteNames.customerBookings), not pop back to the detail.
      signInAs('cust-101');
      var submitted = false;
      await tester.pumpWidget(appFor(CustomerDisputeView(
        initialBookingId: 'RH-849201',
        onDisputeSubmitted: () => submitted = true,
      )));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField,
            'Describe what happened with dates, amounts, and showroom staff names...'),
        'Showroom charged Rs. 3,000 for pre-existing scratches.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit Claim'));
      await tester.pumpAndSettle();
      expect(submitted, isTrue);
    });
  });
}
