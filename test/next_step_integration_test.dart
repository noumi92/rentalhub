import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_bookings_view.dart';
import 'package:rentalhub/features/customer/presentation/widgets/customer_bookings_list_helpers.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_manual_booking_receipt_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/requested_booking_detail.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Next-step batch (2026-11-21), coordinator integration: the router
// wiring for the customer callbacks, the `?tab=all` save
// navigations, the unconditional tab/filter sync (go_router page keys
// are path-only, so a `go()` with a new query string reuses the list
// page — a change-detecting sync would miss consecutive saves), and
// the two navigate-back gaps Worker B flagged (detail-path
// approve/reject, manual-booking receipt Done).
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

  GoRouter routerFor({
    required Widget home,
    String initialLocation = '/',
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(
          path: '/owner/requests',
          builder: (_, __) => const Scaffold(body: Text('requests')),
        ),
        GoRoute(
          path: '/customer/bookings',
          builder: (_, __) => const Scaffold(body: Text('bookings')),
        ),
      ],
    );
  }

  Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
  }

  String location(GoRouter router) =>
      router.routeInformationProvider.value.uri.toString();

  BookingEntity entity({
    String id = 'B1',
    String status = 'requested',
    String customerId = 'cust-1',
  }) =>
      BookingEntity(
        bookingId: id,
        customerId: customerId,
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime.now().add(const Duration(hours: 5)),
        returnTime: DateTime.now().add(const Duration(days: 2)),
        totalAmount: 9000,
        advanceRequired: 3000,
        remainingBalance: 9000,
        status: status,
        customerName: 'Test Customer',
        customerPhone: '03001234567',
        vehicleName: 'Honda Civic',
      );

  void signInAs(String uid) {
    SignedInUser.override = SignedInUserData(
      uid: uid,
      displayName: 'Next Step',
      phoneNumber: '03001234567',
    );
  }

  Future<BookingEntity> seedBooking({
    required String customerId,
    required String shopId,
    String customerName = 'View Customer',
    String vehicleName = 'Honda Civic',
    String status = 'requested',
  }) async {
    final ds = sl<BookingRemoteDataSource>();
    final created = await ds.createBookingRequest(
      customerId: customerId,
      shopId: shopId,
      vehicleId: 'veh-ns-${vehicleName.replaceAll(' ', '-')}',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: DateTime.now().add(const Duration(hours: 5)),
      returnTime: DateTime.now().add(const Duration(days: 2)),
      totalAmount: 9000,
      advanceRequired: 3000,
      vehicleName: vehicleName,
      customerName: customerName,
    );
    if (status == 'requested') return created;
    await ds.updateBookingStatus(
        bookingId: created.bookingId, status: status);
    return created.copyWith(status: status);
  }

  group('customerTabIndexFromName', () {
    test('maps every tab name and falls back to All', () {
      expect(customerTabIndexFromName('all'), 0);
      expect(customerTabIndexFromName('pending'), 1);
      expect(customerTabIndexFromName('approved'), 2);
      expect(customerTabIndexFromName('active'), 3);
      expect(customerTabIndexFromName('disputed'), 4);
      expect(customerTabIndexFromName('done'), 5);
      expect(customerTabIndexFromName('bogus'), 0);
      expect(customerTabIndexFromName(null), 0);
    });
  });

  group('CustomerBookingsView tab sync', () {
    testWidgets('a rebuilt widget with the same initialTab resets to All',
        (tester) async {
      const uid = 'cust-ns-sync';
      signInAs(uid);
      await seedBooking(
          customerId: uid,
          shopId: 'shop-1',
          vehicleName: 'Sync Disputed',
          status: 'disputed');
      await seedBooking(
          customerId: uid,
          shopId: 'shop-1',
          vehicleName: 'Sync Completed',
          status: 'completed');

      // First build: All selected, both bookings visible.
      await tester.pumpWidget(appFor(const CustomerBookingsView()));
      await tester.pumpAndSettle();
      expect(find.text('Sync Disputed'), findsOneWidget);
      expect(find.text('Sync Completed'), findsOneWidget);

      // Tap Disputed: only the disputed booking shows.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Disputed'));
      await tester.pumpAndSettle();
      expect(find.text('Sync Disputed'), findsOneWidget);
      expect(find.text('Sync Completed'), findsNothing);

      // A fresh navigation rebuilds the SAME page (go_router page
      // keys are path-only, so the State is preserved) with the
      // same initialTab value — the unconditional sync in
      // didUpdateWidget must still reset to All.
      await tester.pumpWidget(appFor(const CustomerBookingsView()));
      await tester.pumpAndSettle();
      expect(find.text('Sync Disputed'), findsOneWidget);
      expect(find.text('Sync Completed'), findsOneWidget);
      final allChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'All'));
      expect(allChip.selected, isTrue);
    });
  });

  group('router wiring (source)', () {
    test('customer list/detail builders pass the new callbacks and ?tab=',
        () {
      final src = File('lib/core/routing/app_router.dart').readAsStringSync();
      expect(src, contains('initialTab: customerTabIndexFromName('));
      expect(src, contains('onViewPass: (booking) => context.push('));
      expect(src, contains('onViewActiveTrip: (booking) => context.push('));
      expect(src, contains('onTrackDispute: (booking) => context.push('));
      expect(src, contains('onViewActiveTrip: () => context.push('));
      expect(src, contains('onTrackDispute: () => context.push('));
      // All four customer save callbacks land on All Bookings.
      final tabAll = RegExp(r"customerBookings\}\?tab=all")
          .allMatches(src)
          .length;
      expect(tabAll, 4);
    });

    test('detail-path approve navigates to All Bookings', () {
      final src = File(
        'lib/features/bookings/presentation/views/owner_payment_accounts_view.dart',
      ).readAsStringSync();
      expect(src, contains('onApproved: (_) => goToAllOwnerBookings(context)'));
    });
  });

  group('navigate-back: detail-path reject + receipt Done', () {
    testWidgets('reject from the requested detail lands on All Bookings',
        (tester) async {
      final created = await seedBooking(
        customerId: 'cust-ns-rej',
        shopId: 'shop-ns-rej',
        customerName: 'Reject Customer',
      );
      final router = routerFor(
        home: Scaffold(
          body: RequestedBookingDetail(
            booking: created,
            onApproved: (_) {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Reject Customer'), findsOneWidget);
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'No cars available',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Request'));
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });

    testWidgets('manual-booking receipt Done lands on All Bookings',
        (tester) async {
      final router = routerFor(
        home: OwnerManualBookingReceiptView(
          booking: entity(id: 'B-rec', status: 'paid'),
          paymentMethod: 'cash',
          rentAmount: 9000,
          driverAmount: 0,
          depositMethod: 'cash',
        ),
      );
      await pumpRouter(tester, router);
      await tester.ensureVisible(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });
  });
}
