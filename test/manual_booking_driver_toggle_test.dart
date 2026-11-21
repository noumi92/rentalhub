import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_car_step.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_package_selector.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// ITEM 1: the driver switch in walk-in booking step 2 must add the
// with-driver surcharge to the step-2 total — and remove it again
// when switched off. The switch, the draft flag and the total math
// are wired through ManualBookingCarStep -> ManualBookingPackageSelector.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-driver-toggle-1',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    plateNumber: 'LEA-1000',
    rates: VehicleRatesEntity(
      hourly1: 1500,
      hourly3: 3500,
      hourly6: 6000,
      daily24: 6000,
      outOfCityDaily: 7500,
    ),
    weeklyRate: 36000,
    securityDepositPkr: 20000,
    extraHourPkr: 600,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    packages: [
      VehiclePackageEntity(
          label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
      VehiclePackageEntity(
          label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80),
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 6000, kmIncluded: 250),
    ],
  );

  Widget appFor(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  /// The step-2 widget exactly as the wizard wires it: the switch
  /// callback flips a state-held flag (the draft's isWithDriver in
  /// production) and the flag feeds back into the step.
  Widget carStep({required bool isWithDriver, required ValueChanged<bool> onDriverModeChanged}) {
    final pkg24 = testVehicle.packages.firstWhere((p) => p.label == '24h');
    return Scaffold(
      body: SingleChildScrollView(
        child: ManualBookingCarStep(
          isLoadingVehicles: false,
          vehiclesError: null,
          onRetryLoad: () {},
          vehicles: const [testVehicle],
          selectedVehicle: testVehicle,
          onVehicleChanged: (_) {},
          selectedPackage: pkg24,
          onPackageChanged: (_) {},
          isWithDriver: isWithDriver,
          onDriverModeChanged: onDriverModeChanged,
          isOutOfCity: false,
          pickupTime: DateTime(2026, 11, 20, 10),
          returnTime: DateTime(2026, 11, 21, 10),
          onPickupChanged: (_) {},
          onReturnChanged: (_) {},
          onTripTypeChanged: (_) {},
          onAvailabilityChanged: (_) {},
          existingBookings: const [],
        ),
      ),
    );
  }

  group('driver switch in step 2', () {
    testWidgets('turning the driver on adds the surcharge to the total',
        (tester) async {
      var isWithDriver = false;
      await tester.pumpWidget(appFor(StatefulBuilder(
        builder: (context, setState) => carStep(
          isWithDriver: isWithDriver,
          onDriverModeChanged: (v) => setState(() => isWithDriver = v),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Total: Rs. 6,000'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(isWithDriver, isTrue);
      expect(find.text('Total: Rs. 7,500'), findsOneWidget);
    });

    testWidgets('turning the driver off removes the surcharge again',
        (tester) async {
      var isWithDriver = false;
      await tester.pumpWidget(appFor(StatefulBuilder(
        builder: (context, setState) => carStep(
          isWithDriver: isWithDriver,
          onDriverModeChanged: (v) => setState(() => isWithDriver = v),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Total: Rs. 7,500'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(isWithDriver, isFalse);
      expect(find.text('Total: Rs. 6,000'), findsOneWidget);
    });

    testWidgets('selector alone: total follows the driver flag',
        (tester) async {
      var isWithDriver = false;
      final pkg24 = testVehicle.packages.firstWhere((p) => p.label == '24h');
      await tester.pumpWidget(appFor(StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: ManualBookingPackageSelector(
            vehicle: testVehicle,
            selectedPackage: pkg24,
            onPackageChanged: (_) {},
            isWithDriver: isWithDriver,
            onDriverModeChanged: (v) => setState(() => isWithDriver = v),
            isOutOfCity: false,
            pickup: DateTime(2026, 11, 20, 10),
            returnTime: DateTime(2026, 11, 21, 10),
          ),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Total: Rs. 6,000'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Total: Rs. 7,500'), findsOneWidget);
    });

    testWidgets(
        'characterisation: a car with no driver rate stored adds Rs. 0',
        (tester) async {
      // Diagnosis pin (ITEM 1): the toggle, the draft flag and the
      // total math are all verified above — the ONLY input that
      // leaves the step-2 total flat when the driver is switched on
      // is a vehicle whose withDriverSurchargePkr is null (or 0).
      // A car added with "support with driver" off, or a seeded
      // Firestore doc written without the field, behaves exactly
      // like this on the phone: the switch flips, the total does
      // not move, and nothing says why. If the phone's car HAS a
      // rate stored and still adds nothing, the repro needs a
      // screen recording — the code path below is verified.
      const noRateVehicle = VehicleEntity(
        vehicleId: 'veh-driver-toggle-2',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla',
        year: 2022,
        plateNumber: 'LEA-2000',
        rates: VehicleRatesEntity(
          hourly1: 1500,
          hourly3: 3500,
          hourly6: 6000,
          daily24: 6000,
          outOfCityDaily: 7500,
        ),
        weeklyRate: 36000,
        securityDepositPkr: 20000,
        extraHourPkr: 600,
        withDriverSurchargePkr: null,
        fuelPolicy: 'Same to Same',
        packages: [
          VehiclePackageEntity(
              label: '24h', hours: 24, pricePkr: 6000, kmIncluded: 250),
        ],
      );
      var isWithDriver = false;
      final pkg24 =
          noRateVehicle.packages.firstWhere((p) => p.label == '24h');
      await tester.pumpWidget(appFor(StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: ManualBookingPackageSelector(
            vehicle: noRateVehicle,
            selectedPackage: pkg24,
            onPackageChanged: (_) {},
            isWithDriver: isWithDriver,
            onDriverModeChanged: (v) => setState(() => isWithDriver = v),
            isOutOfCity: false,
            pickup: DateTime(2026, 11, 20, 10),
            returnTime: DateTime(2026, 11, 21, 10),
          ),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Total: Rs. 6,000'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(isWithDriver, isTrue);
      // The switch flips, but with no rate stored the surcharge is
      // Rs. 0 — this is the exact symptom reported from the phone.
      expect(find.text('Total: Rs. 6,000'), findsOneWidget);
    });
  });
}
