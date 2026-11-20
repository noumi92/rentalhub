import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/handover/data/datasources/pdf_contract_generator.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_manual_booking_confirm_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/booking_fare_breakdown.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// 010b night stay + tolls (deck p.4, 024b): nights = days − 1, the
// stay applies to out-of-city WITH-DRIVER trips only, tolls &
// parking is a note (paid by customer / included in rent), never an
// amount. The breakdown shows both rows when the vehicle is passed;
// the three owner detail callers only have the booking, so they show
// neither. The manual confirm step books totalFor, which now
// includes the night stay.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'rentalhub_locked_role': 'owner'});
    await di.initDependencies();
  });

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-night-1',
    shopId: 'shop-1',
    make: 'Honda',
    model: 'Civic Oriel',
    year: 2021,
    plateNumber: 'LEA-4820',
    rates: VehicleRatesEntity(daily24: 9000, outOfCityDaily: 11500),
    weeklyRate: 52000,
    securityDepositPkr: 20000,
    advanceRequiredPkr: 3000,
    extraHourPkr: 600,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    driverNightStayPkr: 2000,
    tollsPaidBy: 'customer',
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

  /// Same vehicle with NO stored night-stay rate or tolls choice —
  /// the deck defaults (Rs 2,000/night, paid by customer) apply.
  const testVehicleNoRate = VehicleEntity(
    vehicleId: 'veh-night-1',
    shopId: 'shop-1',
    make: 'Honda',
    model: 'Civic Oriel',
    year: 2021,
    plateNumber: 'LEA-4820',
    rates: VehicleRatesEntity(daily24: 9000, outOfCityDaily: 11500),
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

  BookingEntity bookingFor({
    String tripType = 'out_of_city',
    bool isWithDriver = true,
    DateTime? pickup,
    DateTime? returnTime,
    int totalAmount = 43000,
  }) {
    return BookingEntity(
      bookingId: 'RH-night',
      customerId: 'cust-night',
      shopId: 'shop-1',
      vehicleId: 'veh-night-1',
      packageType: '24h',
      isWithDriver: isWithDriver,
      pickupTime: pickup ?? DateTime(2026, 10, 26, 10),
      returnTime: returnTime ?? DateTime(2026, 10, 29, 10),
      totalAmount: totalAmount,
      advanceRequired: 3000,
      advancePaid: 0,
      remainingBalance: totalAmount,
      tripType: tripType,
      customerName: 'Night Customer',
    );
  }

  Widget appFor(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  group('night-stay math', () {
    test('3 days -> 2 nights', () {
      expect(
          nightStayNightsFor(
              DateTime(2026, 10, 26, 10), DateTime(2026, 10, 29, 10)),
          2);
    });

    test('1 day -> 0 nights', () {
      expect(
          nightStayNightsFor(
              DateTime(2026, 10, 26, 10), DateTime(2026, 10, 27, 10)),
          0);
    });

    test('out-of-city with-driver: 2 nights x Rs 2,000 = Rs 4,000', () {
      expect(
          nightStayTotalFor(
            vehicle: testVehicle,
            isWithDriver: true,
            isOutOfCity: true,
            pickup: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 29, 10),
          ),
          4000);
    });

    test('custom per-night rate is honoured', () {
      expect(
          nightStayTotalFor(
            vehicle: testVehicle.copyWith(driverNightStayPkr: 2500),
            isWithDriver: true,
            isOutOfCity: true,
            pickup: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 29, 10),
          ),
          5000);
    });

    test('unset rate falls back to the Rs 2,000 deck default', () {
      expect(
          nightStayTotalFor(
            vehicle: testVehicleNoRate,
            isWithDriver: true,
            isOutOfCity: true,
            pickup: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 29, 10),
          ),
          4000);
    });

    test('no night stay for 1-day trips', () {
      expect(
          nightStayTotalFor(
            vehicle: testVehicle,
            isWithDriver: true,
            isOutOfCity: true,
            pickup: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 27, 10),
          ),
          0);
    });

    test('no night stay for in-city trips', () {
      expect(
          nightStayTotalFor(
            vehicle: testVehicle,
            isWithDriver: true,
            isOutOfCity: false,
            pickup: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 29, 10),
          ),
          0);
    });

    test('no night stay for self-drive trips', () {
      expect(
          nightStayTotalFor(
            vehicle: testVehicle,
            isWithDriver: false,
            isOutOfCity: true,
            pickup: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 29, 10),
          ),
          0);
    });
  });

  group('fare breakdown rows (widget)', () {
    testWidgets('out-of-city with-driver shows night stay + tolls note',
        (tester) async {
      await tester.pumpWidget(appFor(BookingFareBreakdown(
        booking: bookingFor(),
        vehicle: testVehicle,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Driver night stay (2 nights)'), findsOneWidget);
      expect(find.text('Rs. 4,000'), findsOneWidget);
      expect(find.text('Tolls & parking — paid by customer'),
          findsOneWidget);
      // Daily rate is net of the stay: 13,000 x 3 + 4,000 = 43,000.
      // The total appears twice (total row + remaining, nothing paid).
      expect(find.text('Rs. 39,000'), findsOneWidget);
      expect(find.text('Rs. 43,000'), findsWidgets);
    });

    testWidgets('tolls included renders the included note', (tester) async {
      await tester.pumpWidget(appFor(BookingFareBreakdown(
        booking: bookingFor(),
        vehicle: testVehicle.copyWith(tollsPaidBy: 'included'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Driver night stay (2 nights)'), findsOneWidget);
      expect(
          find.text('Tolls & parking — included in rent'), findsOneWidget);
    });

    testWidgets('unset vehicle rate/tolls use the defaults', (tester) async {
      await tester.pumpWidget(appFor(BookingFareBreakdown(
        booking: bookingFor(),
        vehicle: testVehicleNoRate,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Driver night stay (2 nights)'), findsOneWidget);
      expect(find.text('Rs. 4,000'), findsOneWidget);
      expect(find.text('Tolls & parking — paid by customer'),
          findsOneWidget);
    });

    testWidgets('1-day out-of-city trip: tolls note, no night stay',
        (tester) async {
      await tester.pumpWidget(appFor(BookingFareBreakdown(
        booking: bookingFor(
            pickup: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 27, 10),
            totalAmount: 13000),
        vehicle: testVehicle,
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Driver night stay'), findsNothing);
      expect(find.text('Tolls & parking — paid by customer'),
          findsOneWidget);
    });

    testWidgets('in-city trip shows neither row', (tester) async {
      await tester.pumpWidget(appFor(BookingFareBreakdown(
        booking: bookingFor(tripType: 'in_city', totalAmount: 27000),
        vehicle: testVehicle,
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Driver night stay'), findsNothing);
      expect(find.textContaining('Tolls & parking'), findsNothing);
    });

    testWidgets('self-drive out-of-city: tolls note, no night stay',
        (tester) async {
      await tester.pumpWidget(appFor(BookingFareBreakdown(
        booking: bookingFor(isWithDriver: false, totalAmount: 34500),
        vehicle: testVehicle,
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Driver night stay'), findsNothing);
      expect(find.text('Tolls & parking — paid by customer'),
          findsOneWidget);
    });

    testWidgets('no vehicle: neither row (owner detail callers)',
        (tester) async {
      await tester.pumpWidget(
          appFor(BookingFareBreakdown(booking: bookingFor())));
      await tester.pumpAndSettle();
      expect(find.textContaining('Driver night stay'), findsNothing);
      expect(find.textContaining('Tolls & parking'), findsNothing);
      expect(find.text('Rs. 43,000'), findsWidgets);
    });
  });

  group('manual confirm books the stay-inclusive total', () {
    testWidgets('confirm shows the stay and books Rs. 43,000',
        (tester) async {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      // The confirm step navigates with go_router, so the test app
      // needs a router; the receipt route is a stub — the booked
      // total is asserted against the data source below. Step-3
      // money for this out-of-city with-driver trip: rent 34,500
      // (3 × 11,500 out-of-city day) + driver 8,500 (3 × 1,500
      // surcharge + 2 × 2,000 night stay) = 43,000.
      final router = GoRouter(
        initialLocation: '/confirm',
        routes: [
          GoRoute(
            path: '/confirm',
            builder: (_, __) => OwnerManualBookingConfirmView(
              customerId: 'cust-counter-1',
              customerName: 'Counter Customer',
              customerPhone: '03001234567',
              customerCnic: '35202-1234567-1',
              vehicle: testVehicle,
              package: pkg24,
              isWithDriver: true,
              isOutOfCity: true,
              pickupTime: DateTime(2026, 10, 26, 10),
              returnTime: DateTime(2026, 10, 29, 10),
              rentAmount: 34500,
              driverAmount: 8500,
              advanceReceived: 3000,
              paymentMethod: 'cash',
              depositMethod: 'cash',
              addRemainingToDues: true,
            ),
          ),
          GoRoute(
            path: '/owner/manual-booking/receipt',
            builder: (_, __) =>
                const Scaffold(body: Text('receipt-stub')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Driver night stay (2 nights)'), findsOneWidget);
      expect(find.text('Rs. 4,000'), findsOneWidget);
      expect(find.text('Tolls & parking — paid by customer'),
          findsOneWidget);

      await tester.ensureVisible(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      expect(find.textContaining('receipt-stub'), findsOneWidget);

      // The stored booking total is the package total (39,000) plus
      // the 2-night stay (4,000) — the same sum the breakdown shows.
      final ds = di.sl<BookingRemoteDataSource>();
      final bookings = await ds.getShopBookings('shop-1');
      final booked = bookings.firstWhere(
          (b) => b.customerName == 'Counter Customer');
      expect(booked.totalAmount, 43000);
      expect(booked.tripType, 'out_of_city');
      expect(booked.isWithDriver, true);
    });
  });

  group('agreement PDF night stay + tolls', () {
    test('PDF night-stay math matches the fare breakdown', () {
      expect(
          PdfContractGenerator.nightStayNights(
              DateTime(2026, 10, 26, 10), DateTime(2026, 10, 29, 10)),
          2);
      expect(
          PdfContractGenerator.nightStayNights(
              DateTime(2026, 10, 26, 10), DateTime(2026, 10, 27, 10)),
          0);
      expect(
          PdfContractGenerator.nightStayTotal(
            isWithDriver: true,
            isOutOfCity: true,
            pickupTime: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 29, 10),
            driverNightStayPkr: 2000,
          ),
          4000);
      expect(
          PdfContractGenerator.nightStayTotal(
            isWithDriver: false,
            isOutOfCity: true,
            pickupTime: DateTime(2026, 10, 26, 10),
            returnTime: DateTime(2026, 10, 29, 10),
            driverNightStayPkr: 2000,
          ),
          0);
    });

    test('generateA4Agreement with out-of-city charges is a real PDF',
        () async {
      final bytes = await PdfContractGenerator.generateA4Agreement(
        agreementId: 'RH-night-pdf',
        shopName: 'Test Motors',
        customerName: 'Night Customer',
        cnicNumber: '35202-1234567-1',
        customerPhone: '03001234567',
        vehicleDetails: 'Honda Civic Oriel',
        packageType: '24h',
        isWithDriver: true,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 43000,
        advancePaid: 3000,
        securityDeposit: 20000,
        initialOdometer: 45200,
        fuelLevel: 'Half',
        damageNotes: const [],
        tripType: 'out_of_city',
        driverNightStayPkr: 2000,
        tollsPaidBy: 'customer',
      );
      expect(bytes.isNotEmpty, true);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
