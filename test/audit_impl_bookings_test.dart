import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/bookings/presentation/views/owner_payment_accounts_view.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/services/walk_in_booking_service.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_confirmed_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_manual_booking_confirm_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_payment_verification_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/guarantor_picker.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_package_selector.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/booking_fare_breakdown.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/request_detail_checks.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/request_triage_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/triage_trust_row.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Audit §5 items 1, 2, 3, 16 (O14–O18): manual booking with dates +
// trip type + confirm step, requests list with Rejected tab + search,
// fare breakdowns, the Booking Confirmed screen, the pre-accept
// checklist, the Confirm Terms step and request-to-manual conversion.
//
// NOTE: the widget tests below need the registrar's .arb keys
// (bookingFare*, bookingCheck*, bookingConfirmed*, manualBookingNext,
// bookingSearchHint, bookingEmptyRejected, bookingDaysCount — see
// audit_impl_manifest_worker_a.md). The unit tests need no l10n.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'rentalhub_locked_role': 'owner'});
    await di.initDependencies();
  });

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-audit-1',
    shopId: 'shop-1',
    make: 'Honda',
    model: 'Civic Oriel',
    year: 2021,
    plateNumber: 'LEA-4820',
    rates: VehicleRatesEntity(
      hourly1: 1500,
      hourly3: 3500,
      hourly6: 6000,
      daily24: 9000,
      outOfCityDaily: 11500,
    ),
    weeklyRate: 52000,
    securityDepositPkr: 20000,
    advanceRequiredPkr: 3000,
    extraHourPkr: 600,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    packages: [
      VehiclePackageEntity(
          label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
      VehiclePackageEntity(
          label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80),
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 9000, kmIncluded: 250),
      VehiclePackageEntity(
          label: 'Weekly', hours: 168, pricePkr: 52000, kmIncluded: 1750),
    ],
  );

  BookingModel modelFor(String id, String name) {
    return BookingModel(
      bookingId: id,
      customerId: 'cust-$id',
      shopId: 'shop-1',
      vehicleId: 'veh-audit-1',
      packageType: '24h',
      pickupTime: DateTime(2026, 10, 26, 10),
      returnTime: DateTime(2026, 10, 29, 10),
      totalAmount: 21000,
      advanceRequired: 5000,
      remainingBalance: 21000,
      customerName: name,
      customerPhone: '03001234567',
      customerCnic: '35202-1234567-1',
      vehicleName: 'Honda Civic Oriel',
    );
  }

  Widget appFor(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  group('day counts', () {
    test('26 Oct 10:00 -> 29 Oct 10:00 is 3 days', () {
      expect(
          dayCountBetween(
              DateTime(2026, 10, 26, 10), DateTime(2026, 10, 29, 10)),
          3);
    });

    test('a sub-day rental still counts as 1 day', () {
      expect(
          dayCountBetween(
              DateTime(2026, 10, 26, 10), DateTime(2026, 10, 26, 16)),
          1);
    });

    test('25 hours rounds up to 2 days', () {
      expect(
          dayCountBetween(
              DateTime(2026, 10, 26, 10), DateTime(2026, 10, 27, 11)),
          2);
    });

    test('bookingDayCount reads the booking dates', () {
      expect(bookingDayCount(modelFor('RH-day', 'Day Counter')), 3);
    });
  });

  group('manual totals: trip type + dates', () {
    test('out-of-city scales the package by the out-city ratio', () {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: false,
          isOutOfCity: true,
          pickup: DateTime(2026, 10, 26, 10),
          returnTime: DateTime(2026, 10, 27, 10),
        ),
        11500,
      );
      expect(
        ManualBookingPackageSelector.unitFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: false,
          isOutOfCity: true,
        ),
        11500,
      );
    });

    test('a 24h package multiplies by days, hourly packages do not', () {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      final pkg6 = testVehicle.packages.firstWhere((p) => p.label == '6h');
      final weekly =
          testVehicle.packages.firstWhere((p) => p.label == 'Weekly');
      final pickup = DateTime(2026, 10, 26, 10);
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: false,
          pickup: pickup,
          returnTime: DateTime(2026, 10, 29, 10),
        ),
        27000,
      );
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg6,
          isWithDriver: false,
          pickup: pickup,
          returnTime: DateTime(2026, 10, 29, 10),
        ),
        6000,
      );
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: weekly,
          isWithDriver: false,
          pickup: pickup,
          returnTime: DateTime(2026, 11, 9, 10),
        ),
        104000,
      );
    });

    test('without dates the old single-unit total is returned', () {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: false,
        ),
        9000,
      );
    });
  });

  group('advance recording: paid only when the advance is covered', () {
    test('a partial advance leaves the booking approved', () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-adv-1',
        shopId: 'shop-1',
        vehicleId: 'veh-audit-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Partial Payer',
      );
      final updated = await ds.recordAdvancePayment(
          bookingId: created.bookingId, advanceAmount: 1000);
      expect(updated.status, 'approved');
      expect(updated.advancePaid, 1000);
      expect(updated.remainingBalance, 8000);
    });

    test('a full advance marks the booking paid', () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-adv-2',
        shopId: 'shop-1',
        vehicleId: 'veh-audit-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Full Payer',
      );
      final updated = await ds.recordAdvancePayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      expect(updated.status, 'paid');
      expect(updated.advancePaid, 3000);
      expect(updated.remainingBalance, 6000);
    });
  });

  group('walk-in service: no longer instantly paid', () {
    Future<BookingModel> walkIn(int received) async {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      final created = await WalkInBookingService.createWalkInBooking(
        name: 'Counter Customer',
        phone: '03001234567',
        cnic: '35202-1234567-1',
        guarantor: null,
        vehicle: testVehicle,
        package: pkg24,
        isWithDriver: false,
        rentAmount: 9000,
        advanceRequired: 3000,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 27, 10),
        tripType: 'in_city',
        advanceReceived: received,
      );
      return BookingModel.fromEntity(created);
    }

    test('0 advance -> approved with the full balance due', () async {
      final booking = await walkIn(0);
      expect(booking.status, 'approved');
      expect(booking.advancePaid, 0);
      expect(booking.remainingBalance, 9000);
      expect(booking.pickupTime, DateTime(2026, 10, 26, 10));
      expect(booking.tripType, 'in_city');
    });

    test('partial advance -> approved with the rest due', () async {
      final booking = await walkIn(1000);
      expect(booking.status, 'approved');
      expect(booking.advancePaid, 1000);
      expect(booking.remainingBalance, 8000);
    });

    test('full advance -> paid', () async {
      final booking = await walkIn(3000);
      expect(booking.status, 'paid');
      expect(booking.advancePaid, 3000);
      expect(booking.remainingBalance, 6000);
    });
  });

  group('request cards + fare breakdown (widget)', () {
    testWidgets('triage card shows pickup/return dates and day count',
        (tester) async {
      await tester.pumpWidget(appFor(RequestTriageCard(
        booking: modelFor('RH-card', 'Card Customer'),
        onApprove: () {},
        onReject: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Oct 26'), findsOneWidget);
      expect(find.textContaining('Oct 29'), findsOneWidget);
      expect(find.textContaining('3 days'), findsOneWidget);
    });

    testWidgets('fare breakdown shows daily rate x days and remaining',
        (tester) async {
      await tester.pumpWidget(appFor(BookingFareBreakdown(
        booking: modelFor('RH-fare', 'Fare Customer'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Fare breakdown'), findsOneWidget);
      expect(find.textContaining('7,000'), findsOneWidget);
      expect(find.text('Rs. 21,000'), findsWidgets);
      expect(find.textContaining('26 Oct 2026'), findsOneWidget);
      expect(find.text('In-City'), findsOneWidget);
    });

    testWidgets('out-of-city bookings carry the Out-of-City tag',
        (tester) async {
      final out = BookingModel.fromEntity(modelFor('RH-out', 'Out Customer')
          .copyWith(tripType: 'out_of_city'));
      await tester.pumpWidget(appFor(BookingFareBreakdown(booking: out)));
      await tester.pumpAndSettle();
      expect(find.text('Out-of-City'), findsOneWidget);
    });
  });

  group('Booking Confirmed screen (widget)', () {
    testWidgets('banner, handover time and three actions render',
        (tester) async {
      final booking = BookingModel.fromEntity(modelFor('RH-conf', 'Confirmed')
          .copyWith(status: 'paid', advancePaid: 5000));
      await tester.pumpWidget(
          appFor(OwnerBookingConfirmedView(booking: booking)));
      await tester.pumpAndSettle();
      expect(find.text('Booking Confirmed'), findsWidgets);
      expect(find.textContaining('Handover scheduled'), findsOneWidget);
      expect(find.textContaining('26 Oct 2026'), findsOneWidget);
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('View Booking'), findsOneWidget);
      expect(find.text('Message Customer'), findsOneWidget);
      expect(find.text('Rs. 21,000'), findsOneWidget);
      expect(find.text('Rs. 16,000'), findsOneWidget);
    });

    testWidgets('O20: countdown, Reserved chip, checklist, QR scan and Call render',
        (tester) async {
      final now = DateTime.now();
      // copyWith carries no pickup/return, so the future-pickup
      // booking is built directly (same fields as modelFor).
      final booking = BookingModel(
        bookingId: 'RH-conf2',
        customerId: 'cust-RH-conf2',
        shopId: 'shop-1',
        vehicleId: 'veh-audit-1',
        packageType: '24h',
        pickupTime: now.add(const Duration(hours: 5)),
        returnTime: now.add(const Duration(days: 2)),
        totalAmount: 21000,
        advanceRequired: 5000,
        advancePaid: 5000,
        remainingBalance: 16000,
        status: 'paid',
        customerName: 'Confirmed Two',
        customerPhone: '03001234567',
        vehicleName: 'Honda Civic Oriel',
      );
      await tester.pumpWidget(
          appFor(OwnerBookingConfirmedView(booking: booking)));
      await tester.pumpAndSettle();
      expect(find.text('COUNTDOWN TO PICKUP'), findsOneWidget);
      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Approval checklist'), findsOneWidget);
      expect(find.text('Request Approved'), findsOneWidget);
      expect(find.text('Advance Received'), findsOneWidget);
      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('Return'), findsOneWidget);
      // Paid: request + advance done, pickup + return pending.
      expect(find.text('Done'), findsNWidgets(2));
      expect(find.text('Pending'), findsNWidgets(2));
      expect(find.text('Scan Customer QR at Pickup'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Message Customer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('O17 request detail: note, blacklist line, split KYC badges (widget)', () {
    testWidgets('customer note renders verbatim', (tester) async {
      final booking = BookingModel.fromEntity(
          modelFor('RH-note', 'Note Customer')
              .copyWith(notes: 'Please call before pickup.'));
      await tester.pumpWidget(
          appFor(OwnerPaymentAccountsView(booking: booking)));
      await tester.pumpAndSettle();
      expect(find.text('Customer note'), findsOneWidget);
      expect(find.text('Please call before pickup.'), findsOneWidget);
    });

    testWidgets('no note renders no note section', (tester) async {
      await tester.pumpWidget(appFor(OwnerPaymentAccountsView(
        booking: modelFor('RH-nonote', 'No Note Customer'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Customer note'), findsNothing);
    });

    testWidgets('live blacklist re-check shows Not Blacklisted for a clean CNIC',
        (tester) async {
      // modelFor carries a CNIC; the in-memory blacklist is empty
      // in tests, so the live re-check resolves clean.
      await tester.pumpWidget(appFor(OwnerPaymentAccountsView(
        booking: modelFor('RH-bl', 'Clean Customer'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Not Blacklisted'), findsOneWidget);
    });

    testWidgets('blacklist line override shows Blacklisted', (tester) async {
      await tester.pumpWidget(appFor(const RequestBlacklistLine(
        cnic: '35202-1234567-1',
        isBlacklisted: true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Blacklisted'), findsOneWidget);
      expect(find.text('Not Blacklisted'), findsNothing);
    });

    testWidgets('blacklist line hides without a CNIC', (tester) async {
      await tester.pumpWidget(
          appFor(const RequestBlacklistLine(cnic: null)));
      await tester.pumpAndSettle();
      expect(find.text('Not Blacklisted'), findsNothing);
      expect(find.text('Blacklisted'), findsNothing);
    });

    testWidgets('split KYC badges render per document', (tester) async {
      await tester.pumpWidget(appFor(const TriageTrustRow(
        customerId: 'cust-1',
        trustScore: 4.0,
        kycStatus: 'verified',
        completedTrips: 2,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Verified CNIC'), findsOneWidget);
      expect(find.text('Verified License'), findsOneWidget);
      expect(find.text('KYC verified'), findsNothing);
    });
  });

  group('O19 payment verification: banner, timestamp, renamed reject (widget)', () {
    testWidgets('waiting banner and proof submission time render',
        (tester) async {
      final booking = BookingModel.fromEntity(
          modelFor('RH-proof', 'Proof Customer').copyWith(
        status: 'payment_submitted',
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-4242',
        proofSubmittedAt: DateTime(2026, 11, 6, 14, 30),
      ));
      await tester.pumpWidget(
          appFor(OwnerPaymentVerificationView(booking: booking)));
      await tester.pumpAndSettle();
      expect(find.text('Waiting for your verification'), findsOneWidget);
      expect(find.text('Proof submitted'), findsOneWidget);
      expect(find.textContaining('Nov 6, 2026'), findsOneWidget);
      expect(find.text('TID-4242'), findsOneWidget);
      expect(find.text('Payment Not Received'), findsOneWidget);
      expect(find.text('Reject Proof'), findsNothing);
    });

    testWidgets('no proof submission time renders no timestamp line',
        (tester) async {
      final booking = BookingModel.fromEntity(
          modelFor('RH-proof2', 'Proof Customer Two').copyWith(
        status: 'payment_submitted',
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-4343',
      ));
      await tester.pumpWidget(
          appFor(OwnerPaymentVerificationView(booking: booking)));
      await tester.pumpAndSettle();
      expect(find.text('Waiting for your verification'), findsOneWidget);
      expect(find.text('Proof submitted'), findsNothing);
    });
  });

  group('O19 payment verification: verified amount (widget)', () {
    testWidgets('amount over the required advance is recorded in full',
        (tester) async {
      // An approved booking whose customer paid MORE than the
      // required advance (the proof shows the full rent). Before
      // the fix the view always recorded exactly the required
      // advance, so the excess stayed due and the handover asked
      // for it again.
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      final created = await WalkInBookingService.createWalkInBooking(
        name: 'Proof Customer',
        phone: '03001234567',
        cnic: '35202-1234567-1',
        guarantor: const GuarantorSelection(
            name: 'Bilal Ahmed',
            cnic: '35202-1234567-2',
            phone: '03007654321',
            relationship: 'Brother'),
        vehicle: testVehicle,
        package: pkg24,
        isWithDriver: false,
        rentAmount: 7500,
        advanceRequired: 3000,
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        tripType: 'in_city',
        advanceReceived: 0,
        customerId: 'cust-proof',
        depositAmountPkr: null,
        discountAmountPkr: null,
        paymentMethod: 'cash',
        depositMethod: 'cash',
      );
      expect(created.advancePaid, 0);
      expect(created.totalAmount, 7500);

      final router = GoRouter(
        initialLocation: '/verify',
        routes: [
          GoRoute(
            path: '/verify',
            builder: (context, state) =>
                OwnerPaymentVerificationView(booking: created),
          ),
          GoRoute(
            path: '/owner/booking-confirmed/:id',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('confirmed')),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();

      // Prefilled with the required advance.
      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      expect(tester.widget<TextField>(field).controller?.text, '3000');

      // The customer actually paid the full rent: Rs. 6,000.
      await tester.enterText(field, '6000');
      await tester.pumpAndSettle();
      expect(find.text('Confirm Payment — Rs. 6,000'), findsOneWidget);

      await tester.ensureVisible(find.text('Confirm Payment — Rs. 6,000'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Payment — Rs. 6,000'));
      await tester.pumpAndSettle();

      expect(find.text('confirmed'), findsOneWidget);
      final ds = di.sl<BookingRemoteDataSource>();
      final verified =
          await ds.getBookingById(created.bookingId);
      expect(verified?.advancePaid, 6000);
      expect(verified?.remainingBalance, 1500);
      expect(verified?.status, 'paid');
    });
  });

  group('requested detail: checklist, terms, convert (widget)', () {
    testWidgets('checklist + confirm terms + convert render before Accept',
        (tester) async {
      await tester.pumpWidget(appFor(OwnerPaymentAccountsView(
        booking: modelFor('RH-detail', 'Detail Customer'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Before you accept'), findsOneWidget);
      expect(find.text('Customer KYC documents on file'), findsOneWidget);
      expect(find.text('Car available'), findsOneWidget);
      expect(find.text('Advance received'), findsOneWidget);
      expect(find.text('Confirm Terms'), findsOneWidget);
      expect(find.text('Car Condition'), findsOneWidget);
      expect(find.text('Fuel Level'), findsOneWidget);
      expect(find.text('Mileage'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Convert to manual entry'), findsOneWidget);
      expect(find.text('Fare breakdown'), findsOneWidget);
    });

    testWidgets('confirm terms without ticking explains what is missing',
        (tester) async {
      await tester.pumpWidget(appFor(OwnerPaymentAccountsView(
        booking: modelFor('RH-terms', 'Terms Customer'),
      )));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirm Booking'));
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Tick all four items to confirm the booking.'),
          findsOneWidget);
    });
  });

  group('requests list: Rejected tab + search (widget)', () {
    testWidgets('rejected bookings stay visible under the Rejected tab',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-rej-1',
        shopId: 'shop-1',
        vehicleId: 'veh-audit-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Rejected Requester',
      );
      await ds.updateBookingStatus(
          bookingId: created.bookingId,
          status: 'rejected',
          rejectionReason: 'No car free');
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rejected ('), findsOneWidget);
      expect(find.text('Rejected Requester'), findsNothing);
      await tester.tap(find.textContaining('Rejected ('));
      await tester.pumpAndSettle();
      expect(find.text('Rejected Requester'), findsOneWidget);
    });

    testWidgets('search narrows the list by customer name',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      await ds.createBookingRequest(
        customerId: 'cust-search-1',
        shopId: 'shop-1',
        vehicleId: 'veh-audit-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Searchable Samina',
      );
      await ds.createBookingRequest(
        customerId: 'cust-search-2',
        shopId: 'shop-1',
        vehicleId: 'veh-audit-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Other Osman',
      );
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      // FG-4: the default triage filter is now proofs-first, so tap
      // New to see fresh 'requested' bookings before searching.
      await tester.tap(find.textContaining('New ('));
      await tester.pumpAndSettle();
      expect(find.text('Searchable Samina'), findsOneWidget);
      expect(find.text('Other Osman'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(
              TextField, 'Search name, phone, car or booking #'),
          'Samina');
      await tester.pumpAndSettle();
      expect(find.text('Searchable Samina'), findsOneWidget);
      expect(find.text('Other Osman'), findsNothing);
    });

    testWidgets('O16: active and completed bookings have their own tabs',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final active = await ds.createBookingRequest(
        customerId: 'cust-active-1',
        shopId: 'shop-1',
        vehicleId: 'veh-audit-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Active Anwar',
      );
      await ds.updateBookingStatus(
          bookingId: active.bookingId, status: 'active');
      final done = await ds.createBookingRequest(
        customerId: 'cust-done-1',
        shopId: 'shop-1',
        vehicleId: 'veh-audit-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Completed Camila',
      );
      await ds.updateBookingStatus(
          bookingId: done.bookingId, status: 'completed');
      await tester.pumpWidget(
          appFor(const OwnerBookingRequestsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      // Both new chips render with counts; neither booking shows
      // under the default Proof-first filter.
      expect(find.textContaining('Active ('), findsOneWidget);
      expect(find.textContaining('Completed ('), findsOneWidget);
      expect(find.text('Active Anwar'), findsNothing);
      expect(find.text('Completed Camila'), findsNothing);
      // Six chips now overflow the 800-wide test viewport, so scroll
      // each chip into view before tapping it.
      await tester.ensureVisible(find.textContaining('Active ('));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Active ('));
      await tester.pumpAndSettle();
      expect(find.text('Active Anwar'), findsOneWidget);
      expect(find.text('Completed Camila'), findsNothing);
      await tester.ensureVisible(find.textContaining('Completed ('));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Completed ('));
      await tester.pumpAndSettle();
      expect(find.text('Completed Camila'), findsOneWidget);
      expect(find.text('Active Anwar'), findsNothing);
    });

    testWidgets('Item 6: calendar button replaces refresh and opens '
        'the fleet calendar route', (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.ownerRequests,
        routes: [
          GoRoute(
            path: RouteNames.ownerRequests,
            builder: (context, state) =>
                const OwnerBookingRequestsView(shopId: 'shop-1'),
          ),
          GoRoute(
            path: RouteNames.ownerFleetCalendar,
            builder: (context, state) =>
                const Scaffold(body: Text('Calendar stub')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      // The redundant reload icon is gone; the QR-scan icon stays.
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('Booking calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Calendar stub'), findsOneWidget);
    });
  });

  group('manual confirm view (widget)', () {
    testWidgets('step 4 summary shows the full money picture',
        (tester) async {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      await tester.pumpWidget(appFor(OwnerManualBookingConfirmView(
        customerId: 'cust-confirm-1',
        customerName: 'Confirm Customer',
        customerPhone: '03001234567',
        customerCnic: '35202-1234567-1',
        vehicle: testVehicle,
        package: pkg24,
        isWithDriver: false,
        isOutOfCity: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        rentAmount: 27000,
        driverAmount: 0,
        advanceReceived: 3000,
        paymentMethod: 'cash',
        depositAmountPkr: 20000,
        depositMethod: 'cash',
        addRemainingToDues: true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Booking Summary'), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Rs. 27,000'), findsWidgets);
      expect(find.text('Rs. 3,000 (Cash)'), findsOneWidget);
      expect(find.text('Rs. 20,000 (Cash)'), findsOneWidget);
      expect(find.text('Rs. 24,000'), findsOneWidget);
      expect(
          find.text(
              'Agreement is generated automatically at handover using saved signatures'),
          findsOneWidget);
      expect(find.text('Confirm Booking'), findsOneWidget);
    });

    testWidgets('a discount lowers the total and the remaining',
        (tester) async {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      await tester.pumpWidget(appFor(OwnerManualBookingConfirmView(
        customerId: 'cust-confirm-1',
        customerName: 'Confirm Customer',
        customerPhone: '03001234567',
        customerCnic: '35202-1234567-1',
        vehicle: testVehicle,
        package: pkg24,
        isWithDriver: false,
        isOutOfCity: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        rentAmount: 27000,
        driverAmount: 0,
        discountAmountPkr: 1000,
        advanceReceived: 1000,
        paymentMethod: 'jazzcash',
        depositAmountPkr: 20000,
        depositMethod: 'cash',
        addRemainingToDues: true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Rs. 26,000'), findsOneWidget);
      expect(find.text('Rs. 25,000'), findsOneWidget);
      expect(find.text('Rs. 1,000 (JazzCash)'), findsOneWidget);
    });
  });
}
