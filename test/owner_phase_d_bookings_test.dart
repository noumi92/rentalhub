import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/bookings/presentation/views/owner_payment_accounts_view.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_manual_booking_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_payment_verification_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_package_selector.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/request_triage_card.dart';

// Owner Module Plan — Phase D: online requests triage, walk-in
// booking fixes, and payment verification with rejection reasons.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Role gate (integration): the owner tests pump the payment
    // accounts view as the shop owner, so the locked role is 'owner'
    // here; the customer route is covered by the default-deny path
    // (no role set) in the immersion tests.
    SharedPreferences.setMockInitialValues(
        {'rentalhub_locked_role': 'owner'});
    await di.initDependencies();
  });

  BookingModel modelFor(String id, String name) {
    return BookingModel(
      bookingId: id,
      customerId: 'cust-$id',
      shopId: 'shop-1',
      vehicleId: 'veh-1',
      packageType: '24h',
      pickupTime: DateTime(2026, 11, 6, 9),
      returnTime: DateTime(2026, 11, 7, 9),
      totalAmount: 9000,
      remainingBalance: 9000,
      customerName: name,
      customerPhone: '0300-1111111',
      vehicleName: 'Honda Civic Oriel',
    );
  }

  group('Phase D (D3) — rejection reasons', () {
    test('booking carries a rejection reason through the model', () {
      final model = modelFor('RH-d1', 'Ayesha Khan');
      final rejected = BookingModel.fromEntity(
          model.copyWith(status: 'rejected', rejectionReason: 'No car free'));
      final restored = BookingModel.fromMap(rejected.toMap(), 'RH-d1');
      expect(restored.status, 'rejected');
      expect(restored.rejectionReason, 'No car free');
      // fromMap backfills a missing origin: 'cust-…' is not a
      // walk-in id, so the restored map gains 'origin': 'online'.
      expect(restored.origin, 'online');
      expect(restored.toMap(), {...rejected.toMap(), 'origin': 'online'});
    });

    test('rejecting a request stores the reason', () async {
      final ds = BookingRemoteDataSource();
      final created = await ds.createBookingRequest(
        customerId: 'cust-d2',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Bilal Ahmed',
      );
      final rejected = await ds.updateBookingStatus(
        bookingId: created.bookingId,
        status: 'rejected',
        rejectionReason: 'Vehicle is booked on those dates.',
      );
      expect(rejected.status, 'rejected');
      expect(rejected.rejectionReason, 'Vehicle is booked on those dates.');
      final stored = await ds.getBookingById(created.bookingId);
      expect(stored?.rejectionReason, 'Vehicle is booked on those dates.');
    });

    test('proof rejection sends the booking back to approved', () async {
      final ds = BookingRemoteDataSource();
      final created = await ds.createBookingRequest(
        customerId: 'cust-d3',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Sara Malik',
      );
      await ds.updateBookingStatus(
          bookingId: created.bookingId, status: 'approved');
      final proofed = await ds.updatePaymentProof(
        bookingId: created.bookingId,
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-123',
      );
      expect(proofed.status, 'payment_submitted');

      final rejected = await ds.rejectPaymentProof(
        bookingId: created.bookingId,
        reason: 'Screenshot is unreadable.',
      );
      expect(rejected.status, 'approved');
      expect(rejected.rejectionReason, 'Screenshot is unreadable.');
      expect(rejected.paymentProofUrl, 'https://example.com/proof.jpg');

      // A fresh proof clears the old reason.
      final resubmitted = await ds.updatePaymentProof(
        bookingId: created.bookingId,
        paymentProofUrl: 'https://example.com/proof2.jpg',
        transactionId: 'TID-124',
      );
      expect(resubmitted.status, 'payment_submitted');
      expect(resubmitted.rejectionReason, isNull);
      expect(
        () => ds.rejectPaymentProof(bookingId: created.bookingId, reason: ' '),
        throwsArgumentError,
      );
    });
  });

  group('Phase D (D2) — walk-in return time', () {
    test('return time follows the chosen package', () {
      final pickup = DateTime(2026, 11, 6, 9);
      const sixHour = VehiclePackageEntity(
          label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80);
      const daily = VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 9000, kmIncluded: 250);
      const weekly = VehiclePackageEntity(
          label: 'Weekly', hours: 168, pricePkr: 52000, kmIncluded: 1750);
      expect(
        ManualBookingPackageSelector.returnTimeFor(
            pickup: pickup, package: sixHour),
        DateTime(2026, 11, 6, 15),
      );
      expect(
        ManualBookingPackageSelector.returnTimeFor(
            pickup: pickup, package: daily),
        DateTime(2026, 11, 7, 9),
      );
      expect(
        ManualBookingPackageSelector.returnTimeFor(
            pickup: pickup, package: weekly),
        DateTime(2026, 11, 13, 9),
      );
    });
  });

  group('Phase D (D1) — triage filters and reject dialog', () {
    Future<void> createInState(
      BookingRemoteDataSource ds,
      String name,
      String status,
    ) async {
      final created = await ds.createBookingRequest(
        customerId: 'cust-$name',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: name,
      );
      if (status == 'payment_submitted') {
        await ds.updateBookingStatus(
            bookingId: created.bookingId, status: 'approved');
        await ds.updatePaymentProof(
          bookingId: created.bookingId,
          paymentProofUrl: 'https://example.com/proof.jpg',
          transactionId: 'TID-$name',
        );
      } else if (status != 'requested') {
        await ds.updateBookingStatus(
            bookingId: created.bookingId, status: status);
      }
    }

    testWidgets('filter chips show each pipeline stage', (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      await createInState(ds, 'New Requester', 'requested');
      await createInState(ds, 'Proof Sender', 'payment_submitted');
      await createInState(ds, 'Approved Waiter', 'approved');

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerBookingRequestsView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Team B (FG-4): the default filter is now the proof bucket —
      // the most urgent one — so the proof sender shows first.
      expect(find.text('Proof Sender'), findsOneWidget);
      expect(find.text('New Requester'), findsNothing);
      expect(find.text('Approved Waiter'), findsNothing);
      expect(find.text('Verify Payment Proof'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);

      await tester.tap(find.textContaining('New ('));
      await tester.pumpAndSettle();
      expect(find.text('New Requester'), findsOneWidget);
      expect(find.text('Proof Sender'), findsNothing);
      expect(find.text('Approve'), findsOneWidget);

      await tester.tap(find.textContaining('Approved ('));
      await tester.pumpAndSettle();
      expect(find.text('Approved Waiter'), findsOneWidget);
      expect(find.text('Verify Payment Proof'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('rejecting asks for a reason and stores it',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      await createInState(ds, 'Reject Me', 'requested');
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerBookingRequestsView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();
      // Team B (FG-4): the default filter is the proof bucket; the
      // requested booking lives under New.
      await tester.tap(find.textContaining('New ('));
      await tester.pumpAndSettle();
      expect(find.text('Reject Me'), findsOneWidget);

      final card = find.ancestor(
        of: find.text('Reject Me'),
        matching: find.byType(RequestTriageCard),
      );
      await tester.ensureVisible(
          find.descendant(of: card, matching: find.text('Decline')));
      await tester.pumpAndSettle();
      await tester.tap(
          find.descendant(of: card, matching: find.text('Decline')));
      await tester.pumpAndSettle();
      expect(find.text('Reject this request?'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, 'Reason (required)'),
          'Vehicle is booked on those dates.');
      await tester.tap(find.text('Reject Request'));
      await tester.pumpAndSettle();
      expect(find.text('Reject Me'), findsNothing);

      final all = await ds.getShopBookings('shop-1');
      final rejected = all.firstWhere((b) => b.customerName == 'Reject Me');
      expect(rejected.status, 'rejected');
      expect(
          rejected.rejectionReason, 'Vehicle is booked on those dates.');
    });
  });

  group('Phase D (D3) — payment verification view', () {
    Future<BookingModel> proofBooking(BookingRemoteDataSource ds) async {
      final created = await ds.createBookingRequest(
        customerId: 'cust-verify',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Verify Customer',
        customerPhone: '0300-5555555',
        vehicleName: 'Honda Civic Oriel',
      );
      await ds.updateBookingStatus(
          bookingId: created.bookingId, status: 'approved');
      final proofed = await ds.updatePaymentProof(
        bookingId: created.bookingId,
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-999',
      );
      return BookingModel.fromEntity(proofed);
    }

    Widget appFor(BookingModel booking) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                OwnerPaymentVerificationView(booking: booking),
          ),
          GoRoute(
            path: '/owner/booking-confirmed/:id',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Booking Confirmed')),
            ),
          ),
        ],
      );
      return MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }

    testWidgets('approving a proof marks the booking paid and opens the confirmed screen',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await proofBooking(ds);
      await tester.pumpWidget(appFor(booking));
      await tester.pumpAndSettle();
      expect(find.text('TID-999'), findsOneWidget);
      expect(find.textContaining('Confirm Payment'), findsOneWidget);

      // The confirm button sits below the fold in the 800x600 test
      // viewport (the fare breakdown card made the view taller) —
      // scroll it into view first, as a user would on a phone.
      await tester.ensureVisible(find.textContaining('Confirm Payment'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Confirm Payment'));
      await tester.pumpAndSettle();
      // Audit §5 item 3 (O18): approval lands on Booking Confirmed,
      // not straight on handover.
      expect(find.text('Booking Confirmed'), findsOneWidget);
      final stored = await ds.getBookingById(booking.bookingId);
      expect(stored?.status, 'paid');
      expect(stored?.advancePaid, 3000);
    });

    testWidgets('rejecting a proof asks for a reason and reopens the booking',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await proofBooking(ds);
      await tester.pumpWidget(appFor(booking));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Payment Not Received'));
      await tester.tap(find.text('Payment Not Received'));
      await tester.pumpAndSettle();
      expect(find.text('Reject this proof?'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, 'Reason (required)'),
          'Screenshot is unreadable.');
      await tester.tap(find.text('Payment Not Received').last);
      await tester.pumpAndSettle();
      final stored = await ds.getBookingById(booking.bookingId);
      expect(stored?.status, 'approved');
      expect(stored?.rejectionReason, 'Screenshot is unreadable.');
    });
  });

  group('Phase D (D1) — payment accounts are honest', () {
    testWidgets('no configured accounts says so instead of fake ones',
        (tester) async {
      // §10: the accounts view gates on status — a merely `requested`
      // booking renders the requested-state detail, so this
      // accounts-honesty case pumps an approved booking.
      final approved = modelFor('RH-d4', 'Ayesha Khan')
          .copyWith(status: 'approved');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerPaymentAccountsView(booking: approved),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No payment accounts configured for this shop yet.'),
          findsOneWidget);
      expect(find.text('Al-Falah Rent a Car'), findsNothing);
    });

    testWidgets('a requested booking shows the decision detail, not the approved banner',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerPaymentAccountsView(
              booking: modelFor('RH-d4', 'Ayesha Khan')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reservation Request Approved!'), findsNothing);
      expect(find.text('Approve'), findsWidgets);
      expect(find.text('Decline'), findsOneWidget);
    });
  });

  group('Phase D — routing', () {
    test('request detail branches to verification for submitted proofs',
        () async {
      final router =
          await File('lib/core/routing/app_router.dart').readAsString();
      expect(router, contains('OwnerPaymentVerificationView'));
      expect(router, contains("booking.status == 'payment_submitted'"));
    });
  });

  group('Audit §12 — manual booking starts with no demo identity', () {
    testWidgets('step 1 has a customer search, not typed name/phone/CNIC fields',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerManualBookingView(),
        ),
      );
      await tester.pumpAndSettle();

      // Walk-in rework (O21): registered customers only — the old
      // free-text identity fields are gone; the old demo defaults
      // must never appear as real values either.
      expect(find.text('Walk-in Customer'), findsNothing);
      expect(find.text('0300-1122334'), findsNothing);
      expect(find.text('35201-1234567-1'), findsNothing);
      expect(find.widgetWithText(TextField, 'Customer Full Name'),
          findsNothing);
      expect(find.widgetWithText(TextField, 'NADRA CNIC'), findsNothing);
      expect(find.byKey(const Key('manual-booking-customer-search')),
          findsOneWidget);
      expect(find.byKey(const Key('manual-booking-add-customer')),
          findsOneWidget);
      expect(find.text('+ Add New Customer'), findsOneWidget);
    });

    testWidgets('an unregistered prefill shows the add-customer hint',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerManualBookingView(
            prefilledName: 'Ayesha Khan',
            prefilledPhone: '03001234567',
            prefilledCnic: '35202-1234567-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No saved customer matches in the test env, so the step
      // reports the handoff instead of prefilling typed fields.
      expect(
          find.text(
              'This customer is not registered yet — add them first.'),
          findsOneWidget);
      expect(find.byKey(const Key('manual-booking-add-customer')),
          findsOneWidget);
    });
  });

  group('Booking data-model foundation — new fields', () {
    test('origin, proof time, payment account, guarantor relation '
        'and deposit round-trip through the model', () {
      final model = BookingModel(
        bookingId: 'RH-new-1',
        customerId: 'cust-new-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 9000,
        remainingBalance: 9000,
        origin: 'online',
        proofSubmittedAt: DateTime(2026, 11, 6, 10, 30),
        selectedPaymentAccount: 'JazzCash 0300-1111111',
        paymentDeadline: DateTime(2026, 11, 7, 9),
        guarantorRelation: 'Cousin',
        depositAmountPkr: 5000,
      );
      final restored = BookingModel.fromMap(model.toMap(), 'RH-new-1');
      expect(restored.origin, 'online');
      expect(restored.proofSubmittedAt, DateTime(2026, 11, 6, 10, 30));
      expect(restored.selectedPaymentAccount, 'JazzCash 0300-1111111');
      expect(restored.paymentDeadline, DateTime(2026, 11, 7, 9));
      expect(restored.guarantorRelation, 'Cousin');
      expect(restored.depositAmountPkr, 5000);
      expect(restored.toMap(), model.toMap());
    });

    test('updatePaymentProof stamps proofSubmittedAt', () async {
      final ds = BookingRemoteDataSource();
      final created = await ds.createBookingRequest(
        customerId: 'cust-proof-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 9000,
        advanceRequired: 1000,
      );
      expect(created.origin, 'online');
      expect(created.proofSubmittedAt, isNull);
      final proofed = await ds.updatePaymentProof(
        bookingId: created.bookingId,
        paymentProofUrl: 'https://example.test/proof.jpg',
        transactionId: 'TID-1',
      );
      expect(proofed.proofSubmittedAt, isNotNull);
      final reloaded = await ds.getBookingById(created.bookingId);
      expect(reloaded?.proofSubmittedAt, isNotNull);
    });
  });
}
