import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Items 3 + 4 (2026-11-21): the Bookings tab list must reflect
// creates and status changes without a manual refresh, and its
// filter bar must cover every booking status (All / New / Proof /
// Approved / Paid / Active / Disputed / Completed / Rejected /
// Cancelled) at fleet-style full-size labels.
//
// REPRO first: before the fix the view's stream callback drops
// 'paid', 'disputed' and 'cancelled' bookings, so a booking that
// is paid / disputed / cancelled vanishes from the list entirely
// (a full-advance walk-in is born 'paid' and never appears at
// all), and there is no chip under which to find it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'rentalhub_locked_role': 'owner'});
    await di.initDependencies();
  });

  Widget appFor(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  Future<String> createBooking(
    BookingRemoteDataSource ds,
    String name,
  ) async {
    final created = await ds.createBookingRequest(
      customerId: 'cust-live-$name',
      shopId: 'shop-1',
      vehicleId: 'veh-live-1',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: DateTime(2026, 11, 21, 10),
      returnTime: DateTime(2026, 11, 22, 10),
      totalAmount: 9000,
      advanceRequired: 3000,
      customerName: name,
    );
    return created.bookingId;
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    final chip = find.textContaining('$label (');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  // The list lazily builds its cards: a booking below the fold is
  // not in the tree until the list scrolls to it.
  Future<void> expectNameVisible(WidgetTester tester, String name) async {
    await tester.scrollUntilVisible(
      find.text(name),
      300,
      // The first Scrollable is the filter bar's horizontal scroller;
      // the list is the last one.
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text(name), findsOneWidget);
  }

  group('item 3 — list follows creates and status changes', () {
    testWidgets('a booking paid after the list opens stays visible '
        'under Paid without a manual refresh', (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final id = await createBooking(ds, 'Paid Palwasha');
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      expect(find.text('Paid Palwasha'), findsNothing);

      // The owner verifies the payment while looking at the list:
      // the booking must move to Paid, not vanish.
      await ds.verifyPayment(bookingId: id, advanceAmount: 3000);
      await tester.pumpAndSettle();

      await tapChip(tester, 'Paid');
      expect(find.text('Paid Palwasha'), findsOneWidget);
    });

    testWidgets('a full-advance walk-in (born paid) appears under '
        'Paid without a manual refresh', (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();

      // Created after the list is already open, already paid.
      final id = await createBooking(ds, 'Walkin Waqas');
      await ds.verifyPayment(bookingId: id, advanceAmount: 9000);
      await tester.pumpAndSettle();

      await tapChip(tester, 'Paid');
      expect(find.text('Walkin Waqas'), findsOneWidget);
    });

    testWidgets('a cancelled booking stays visible under Cancelled',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final id = await createBooking(ds, 'Cancelled Celine');
      await ds.updateBookingStatus(bookingId: id, status: 'cancelled');
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();

      await tapChip(tester, 'Cancelled');
      expect(find.text('Cancelled Celine'), findsOneWidget);
    });

    testWidgets('a disputed booking stays visible under Disputed',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final id = await createBooking(ds, 'Disputed Daniyal');
      await ds.updateBookingStatus(bookingId: id, status: 'disputed');
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();

      await tapChip(tester, 'Disputed');
      expect(find.text('Disputed Daniyal'), findsOneWidget);
    });

    testWidgets('a new requested booking lands in the open list '
        'without a manual refresh', (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();

      await createBooking(ds, 'Fresh Farah');
      await tester.pumpAndSettle();

      await tapChip(tester, 'New');
      expect(find.text('Fresh Farah'), findsOneWidget);
    });
  });

  group('item 4 — one fleet-style filter bar, all statuses', () {
    testWidgets('All shows bookings of every status; each status '
        'chip filters to just its own', (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final paidId = await createBooking(ds, 'All Paid Aamir');
      await ds.verifyPayment(bookingId: paidId, advanceAmount: 3000);
      final cancelledId = await createBooking(ds, 'All Cancelled Bilal');
      await ds.updateBookingStatus(
          bookingId: cancelledId, status: 'cancelled');
      final disputedId = await createBooking(ds, 'All Disputed Sana');
      await ds.updateBookingStatus(
          bookingId: disputedId, status: 'disputed');
      await createBooking(ds, 'All New Nadia');

      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();

      // Every status chip renders (fleet-style bar, scrollable).
      for (final label in [
        'All',
        'New',
        'Proof',
        'Approved',
        'Paid',
        'Active',
        'Disputed',
        'Completed',
        'Rejected',
        'Cancelled',
      ]) {
        expect(find.textContaining('$label ('), findsOneWidget,
            reason: 'missing filter chip: $label');
      }

      await tapChip(tester, 'All');
      await expectNameVisible(tester, 'All Paid Aamir');
      await expectNameVisible(tester, 'All Cancelled Bilal');
      await expectNameVisible(tester, 'All Disputed Sana');
      await expectNameVisible(tester, 'All New Nadia');

      await tapChip(tester, 'Paid');
      expect(find.text('All Paid Aamir'), findsOneWidget);
      expect(find.text('All Cancelled Bilal'), findsNothing);
      expect(find.text('All Disputed Sana'), findsNothing);
      expect(find.text('All New Nadia'), findsNothing);

      await tapChip(tester, 'Cancelled');
      expect(find.text('All Cancelled Bilal'), findsOneWidget);
      expect(find.text('All Paid Aamir'), findsNothing);
    });

    testWidgets('filter chips keep full-size 14sp labels',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      await createBooking(ds, 'Label Laila');
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();

      // FleetFilterChips sets 14sp on the label Text itself so the
      // bar scrolls instead of shrinking; the bookings bar must do
      // the same.
      final chipText = tester.widget<Text>(find.textContaining('New ('));
      expect(chipText.style?.fontSize, 14);
    });
  });
}
