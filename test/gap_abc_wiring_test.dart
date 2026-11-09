import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/presentation/widgets/booking_detail_summary.dart';
import 'package:rentalhub/features/finance/utils/settlement_calculator.dart';
import 'package:rentalhub/features/fleet/domain/entities/fixed_route_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/handover/data/datasources/pdf_contract_generator.dart';
import 'package:rentalhub/features/owner/presentation/services/contract_trip_charges.dart';
import 'package:rentalhub/features/owner/presentation/services/return_settlement_service.dart';
import 'package:rentalhub/features/owner/presentation/widgets/contract_paper_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Gaps (a/b/c) wiring — 2026-11-09 Worker 3:
// (a) the agreement PDF prints the vehicle's ACTUAL night-stay /
// tolls rates, and omits both lines when the vehicle can't be loaded;
// (b) the fixed route id + denormalised summary (and the out-of-city
// pricing snapshot) are stored on the booking and shown on detail /
// agreement screens; (c) per-km trips settle on actual km at return.

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

BookingEntity _booking({
  String tripType = 'out_of_city',
  int totalAmount = 35500,
  String? fixedRouteId,
  String? fixedRouteSummary,
  String? outCityMode,
  int? outCityPerKmPkr,
  bool isWithDriver = true,
}) {
  return BookingEntity(
    bookingId: 'RH-TEST-1',
    customerId: 'cust-1',
    shopId: 'shop-1',
    vehicleId: 'veh-1',
    packageType: '24h',
    isWithDriver: isWithDriver,
    pickupTime: DateTime(2026, 11, 10, 10),
    returnTime: DateTime(2026, 11, 13, 10),
    totalAmount: totalAmount,
    remainingBalance: totalAmount,
    tripType: tripType,
    fixedRouteId: fixedRouteId,
    fixedRouteSummary: fixedRouteSummary,
    outCityMode: outCityMode,
    outCityPerKmPkr: outCityPerKmPkr,
  );
}

VehicleEntity _vehicle({
  int? driverNightStayPkr,
  String? tollsPaidBy,
  String? outCityMode,
  int? outCityPerKmPkr,
}) {
  return VehicleEntity(
    vehicleId: 'veh-1',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    plateNumber: 'LEA-22-1',
    rates: const VehicleRatesEntity(daily24: 7000),
    withDriverSurchargePkr: 1500,
    driverNightStayPkr: driverNightStayPkr,
    tollsPaidBy: tollsPaidBy,
    outCityMode: outCityMode,
    outCityPerKmPkr: outCityPerKmPkr,
  );
}

void main() {
  group('gap (a) — PDF trip charges', () {
    test('resolver passes the vehicle actual rates, never defaults', () {
      final charges = resolvePdfTripCharges(
        booking: _booking(),
        vehicle: _vehicle(
            driverNightStayPkr: 2500, tollsPaidBy: 'included'),
      );
      expect(charges.tripType, 'out_of_city');
      expect(charges.driverNightStayPkr, 2500);
      expect(charges.tollsPaidBy, 'included');
    });

    test('resolver omits everything when the vehicle cannot be loaded',
        () {
      final charges =
          resolvePdfTripCharges(booking: _booking(), vehicle: null);
      expect(charges.tripType, isNull);
      expect(charges.driverNightStayPkr, isNull);
      expect(charges.tollsPaidBy, isNull);
    });

    test('in-city booking resolves to in_city (generator omits rows)',
        () {
      final charges = resolvePdfTripCharges(
        booking: _booking(tripType: 'in_city'),
        vehicle: _vehicle(driverNightStayPkr: 2500),
      );
      expect(charges.tripType, 'in_city');
      expect(
        PdfContractGenerator.nightStayTotal(
          isWithDriver: true,
          isOutOfCity: false,
          pickupTime: DateTime(2026, 11, 10, 10),
          returnTime: DateTime(2026, 11, 13, 10),
          driverNightStayPkr: 2500,
        ),
        0,
      );
    });

    test('night stay uses the owner custom rate, not the Rs 2,000 default',
        () {
      // 3-day trip = 2 nights; custom Rs 2,500/night = Rs 5,000.
      expect(
        PdfContractGenerator.nightStayTotal(
          isWithDriver: true,
          isOutOfCity: true,
          pickupTime: DateTime(2026, 11, 10, 10),
          returnTime: DateTime(2026, 11, 13, 10),
          driverNightStayPkr: 2500,
        ),
        5000,
      );
      // No custom rate set: the deck default applies (Rs 2,000).
      expect(
        PdfContractGenerator.nightStayTotal(
          isWithDriver: true,
          isOutOfCity: true,
          pickupTime: DateTime(2026, 11, 10, 10),
          returnTime: DateTime(2026, 11, 13, 10),
        ),
        4000,
      );
    });

    test('generator produces a real PDF with and without trip charges',
        () async {
      Future<List<int>> bytesFor({String? tripType, int? stay}) =>
          PdfContractGenerator.generateA4Agreement(
            agreementId: 'RH-TEST-1',
            shopName: 'Test Motors',
            customerName: 'Test Customer',
            cnicNumber: '35202-1234567-1',
            customerPhone: '+923001234567',
            vehicleDetails: 'Toyota Corolla 2022',
            packageType: '24h',
            isWithDriver: true,
            pickupTime: DateTime(2026, 11, 10, 10),
            returnTime: DateTime(2026, 11, 13, 10),
            totalAmount: 35500,
            advancePaid: 5000,
            securityDeposit: 20000,
            initialOdometer: 45200,
            fuelLevel: '4/4 (Full)',
            damageNotes: const [],
            tripType: tripType,
            driverNightStayPkr: stay,
            tollsPaidBy: 'included',
          );
      // Vehicle missing: null trip type omits the lines, still a PDF.
      final omitted = await bytesFor();
      expect(omitted.length, greaterThan(1000));
      expect(String.fromCharCodes(omitted.take(5)), '%PDF-');
      // Vehicle loaded with a custom rate: real charges, still a PDF.
      final charged =
          await bytesFor(tripType: 'out_of_city', stay: 2500);
      expect(charged.length, greaterThan(1000));
      expect(String.fromCharCodes(charged.take(5)), '%PDF-');
    });
  });

  group('gap (b) — fixed route on the booking', () {
    const route = FixedRouteEntity(
      routeId: 'route-lhr-isb',
      shopId: 'shop-1',
      originCity: 'Lahore',
      destinationCity: 'Islamabad',
      distanceKm: 300,
      fixedPricePkr: 18000,
    );

    test('model round-trips route id, summary and pricing snapshot', () {
      final model = BookingModel.fromEntity(_booking(
        fixedRouteId: route.routeId,
        fixedRouteSummary: route.displayName,
        outCityMode: 'fixedRoute',
      ));
      final restored = BookingModel.fromMap(model.toMap(), model.bookingId);
      expect(restored.fixedRouteId, 'route-lhr-isb');
      expect(restored.fixedRouteSummary, 'Lahore → Islamabad');
      expect(restored.outCityMode, 'fixedRoute');
    });

    test('older bookings without the new fields read back as nulls', () {
      final map = BookingModel.fromEntity(_booking()).toMap()
        ..remove('fixedRouteId')
        ..remove('fixedRouteSummary')
        ..remove('outCityMode')
        ..remove('outCityPerKmPkr');
      final restored = BookingModel.fromMap(map, 'RH-OLD-1');
      expect(restored.fixedRouteId, isNull);
      expect(restored.fixedRouteSummary, isNull);
      expect(restored.outCityMode, isNull);
      expect(restored.outCityPerKmPkr, isNull);
    });

    test('createBookingRequest stores route + snapshot on the booking',
        () async {
      final ds = BookingRemoteDataSource();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: true,
        pickupTime: DateTime(2026, 11, 10, 10),
        returnTime: DateTime(2026, 11, 13, 10),
        totalAmount: 18000,
        advanceRequired: 5000,
        tripType: 'out_of_city',
        fixedRouteId: route.routeId,
        fixedRouteSummary: route.displayName,
        outCityMode: 'fixedRoute',
      );
      expect(booking.fixedRouteId, 'route-lhr-isb');
      expect(booking.fixedRouteSummary, 'Lahore → Islamabad');
      expect(booking.outCityMode, 'fixedRoute');
      final reloaded = await ds.getBookingById(booking.bookingId);
      expect(reloaded?.fixedRouteId, 'route-lhr-isb');
      expect(reloaded?.fixedRouteSummary, 'Lahore → Islamabad');
    });

    testWidgets('customer detail shows the route when stored',
        (tester) async {
      await tester.pumpWidget(_wrap(BookingDetailSummary(
        booking: _booking(
          fixedRouteId: route.routeId,
          fixedRouteSummary: route.displayName,
        ),
      )));
      await tester.pump();
      expect(find.text('Lahore → Islamabad'), findsOneWidget);
      expect(find.text('Fixed route'), findsOneWidget);
    });

    testWidgets('customer detail shows no route row when absent',
        (tester) async {
      await tester.pumpWidget(_wrap(BookingDetailSummary(
        booking: _booking(),
      )));
      await tester.pump();
      expect(find.text('Fixed route'), findsNothing);
      expect(find.text('Lahore → Islamabad'), findsNothing);
    });

    testWidgets('agreement paper shows the route when stored',
        (tester) async {
      await tester.pumpWidget(_wrap(ContractPaperSheet(
        booking: _booking(
          fixedRouteId: route.routeId,
          fixedRouteSummary: route.displayName,
        ),
        odometer: 45200,
        fuelLevel: '4/4 (Full)',
      )));
      await tester.pump();
      expect(find.text('Lahore → Islamabad'), findsOneWidget);
    });
  });

  group('gap (c) — per-km settlement on actual km', () {
    // Estimate: 3 days × 300 km/day × Rs 30 = 27,000, driver
    // 1,500 × 3 = 4,500, night stay 2 × 2,000 = 4,000 → 35,500.
    test('longer than estimated: extra due', () {
      final s = SettlementCalculator.calculatePerKm(
        actualKm: 1000,
        perKmRate: 30,
        driverAllowancePerDay: 1500,
        days: 3,
        isWithDriver: true,
        nightStayTotal: 4000,
        estimatedFare: 35500,
      );
      expect(s.actualFare, 38500);
      expect(s.extraDue, 3000);
      expect(s.refundDue, 0);
    });

    test('shorter than estimated: refund due', () {
      final s = SettlementCalculator.calculatePerKm(
        actualKm: 800,
        perKmRate: 30,
        driverAllowancePerDay: 1500,
        days: 3,
        isWithDriver: true,
        nightStayTotal: 4000,
        estimatedFare: 35500,
      );
      expect(s.actualFare, 32500);
      expect(s.extraDue, 0);
      expect(s.refundDue, 3000);
    });

    test('exactly as estimated: nothing due either way', () {
      final s = SettlementCalculator.calculatePerKm(
        actualKm: 900,
        perKmRate: 30,
        driverAllowancePerDay: 1500,
        days: 3,
        isWithDriver: true,
        nightStayTotal: 4000,
        estimatedFare: 35500,
      );
      expect(s.actualFare, 35500);
      expect(s.extraDue, 0);
      expect(s.refundDue, 0);
    });

    test('self-drive trips add no driver allowance', () {
      final s = SettlementCalculator.calculatePerKm(
        actualKm: 1000,
        perKmRate: 30,
        driverAllowancePerDay: 1500,
        days: 3,
        isWithDriver: false,
        nightStayTotal: 0,
        estimatedFare: 27000,
      );
      expect(s.actualFare, 30000);
      expect(s.extraDue, 3000);
    });

    test('standard settlement is unchanged for non-per-km bookings', () {
      final b = SettlementCalculator.calculate(
        totalKmDriven: 350,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '4/4 (Full)',
        extraHourPkr: 600,
        securityDeposit: 20000,
      );
      expect(b.excessKm, 100);
      expect(b.excessKmCharge, 10000);
      expect(b.netRefund, 10000);
    });

    test('snapshot wins: booked per-km rate beats a later vehicle edit',
        () {
      // Booking was made at Rs 30/km; the vehicle now says perDay.
      final s = ReturnSettlementService.perKmSettlementFor(
        booking: _booking(outCityMode: 'perKm', outCityPerKmPkr: 30),
        totalKmDriven: 1000,
        pricing: const PerKmPricing(
          outCityMode: 'perDay',
          driverAllowancePerDay: 1500,
        ),
      );
      expect(s, isNotNull);
      expect(s!.perKmRate, 30);
      expect(s.extraDue, 3000);
    });

    test('older booking without a snapshot falls back to vehicle rates',
        () {
      final s = ReturnSettlementService.perKmSettlementFor(
        booking: _booking(),
        totalKmDriven: 1000,
        pricing: const PerKmPricing(
          outCityMode: 'perKm',
          outCityPerKmPkr: 40,
          driverAllowancePerDay: 1500,
        ),
      );
      expect(s, isNotNull);
      // 1,000 × 40 + 4,500 driver + 4,000 stay = 48,500 vs 35,500.
      expect(s!.actualFare, 48500);
      expect(s.extraDue, 13000);
    });

    test('non-per-km bookings return null (settle exactly as today)', () {
      const pricing = PerKmPricing(
        outCityMode: 'perKm',
        outCityPerKmPkr: 30,
        driverAllowancePerDay: 1500,
      );
      expect(
        ReturnSettlementService.perKmSettlementFor(
          booking: _booking(tripType: 'in_city'),
          totalKmDriven: 1000,
          pricing: pricing,
        ),
        isNull,
      );
      expect(
        ReturnSettlementService.perKmSettlementFor(
          booking: _booking(outCityMode: 'perDay'),
          totalKmDriven: 1000,
          pricing: pricing,
        ),
        isNull,
      );
      expect(
        ReturnSettlementService.perKmSettlementFor(
          booking: _booking(
            outCityMode: 'fixedRoute',
            fixedRouteId: 'route-lhr-isb',
            fixedRouteSummary: 'Lahore → Islamabad',
          ),
          totalKmDriven: 1000,
          pricing: pricing,
        ),
        isNull,
      );
      // Per-km mode but no rate anywhere: no reconciliation either.
      expect(
        ReturnSettlementService.perKmSettlementFor(
          booking: _booking(outCityMode: 'perKm'),
          totalKmDriven: 1000,
          pricing: const PerKmPricing(outCityMode: 'perKm'),
        ),
        isNull,
      );
    });
  });
}
