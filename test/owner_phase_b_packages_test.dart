import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/presentation/views/rent_package_picker_view.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/data/models/vehicle_model.dart';
import 'package:rentalhub/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/usecases/update_vehicle_pricing_usecase.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_package_selector.dart';

// Owner Module Plan — Phase B (B2): rent packages with real prices and
// on/off toggles, the driver surcharge, deposit/advance/extra-hour and
// fuel policy on the vehicle, and totals computed from the chosen
// package — in the picker and in the counter booking.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-pkg-1',
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
          label: '3h', hours: 3, pricePkr: 3500, enabled: false,
          kmIncluded: 40),
      VehiclePackageEntity(
          label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80),
      VehiclePackageEntity(
          label: '12h', hours: 12, pricePkr: 5400, kmIncluded: 150),
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 9000, kmIncluded: 250),
      VehiclePackageEntity(
          label: 'Weekly', hours: 168, pricePkr: 52000, kmIncluded: 1750),
      VehiclePackageEntity(
          label: 'Monthly', hours: 720, pricePkr: 216000, kmIncluded: 7500),
    ],
  );

  group('Phase B (B2) — package model', () {
    test('packages round-trip through the model', () {
      final model = VehicleModel.fromEntity(testVehicle);
      final restored = VehicleModel.fromMap(model.toMap(), 'veh-pkg-1');
      // Equatable compares runtime types, so compare the maps instead.
      expect(restored.toMap(), model.toMap());
      expect(restored.packages.length, 7);
      expect(restored.enabledPackages.length, 6);
      expect(
        restored.enabledPackages.any((p) => p.label == '3h'),
        isFalse,
      );
    });

    test('old documents without packages derive the seven defaults', () {
      const old = VehicleModel(
        vehicleId: 'veh-old-1',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla Grande',
        year: 2022,
        plateNumber: 'ICT-9912',
        rates: VehicleRatesEntity(
          hourly1: 1400,
          hourly3: 3200,
          hourly6: 5500,
          daily24: 8500,
          outOfCityDaily: 10500,
        ),
        weeklyRate: 50000,
      );
      final packages = old.effectivePackages;
      expect(packages.map((p) => p.label).toList(),
          ['1h', '3h', '6h', '12h', '24h', 'Weekly', 'Monthly']);
      expect(packages[3].pricePkr, (8500 * 0.6).round());
      expect(packages[4].pricePkr, 8500);
      expect(packages[5].pricePkr, 50000);
      // Monthly = daily x 24 (30 days less 20%).
      expect(packages[6].pricePkr, 8500 * 24);
      expect(packages[6].hours, 720);
      expect(packages[6].kmIncluded, 7500);
      expect(packages.every((p) => p.enabled), isTrue);
    });
  });

  group('Phase B (B2) — pricing save', () {
    test('use case writes packages and policy fields', () async {
      final ds = FleetRemoteDataSource();
      final repo = FleetRepositoryImpl(remoteDataSource: ds);
      final useCase = UpdateVehiclePricingUseCase(repo);

      await ds.addVehicle(shopId: 'shop-1', vehicle: testVehicle);
      final updated = testVehicle.copyWith(
        packages: testVehicle.packages
            .map((p) => p.label == '12h'
                ? p.copyWith(pricePkr: 5800, enabled: false)
                : p)
            .toList(),
        rates: const VehicleRatesEntity(
          hourly1: 1500,
          hourly3: 3500,
          hourly6: 6000,
          daily24: 9500,
          outOfCityDaily: 12000,
        ),
        isWithDriverAvailable: false,
        fuelPolicy: 'Full to Full',
      );
      await useCase(vehicleId: 'veh-pkg-1', vehicle: updated);

      final cars = await repo.getShopVehicles('shop-1');
      final saved = cars.firstWhere((c) => c.vehicleId == 'veh-pkg-1');
      expect(saved.rates.daily24, 9500);
      expect(saved.rates.outOfCityDaily, 12000);
      expect(saved.isWithDriverAvailable, isFalse);
      expect(saved.fuelPolicy, 'Full to Full');
      final twelve = saved.packages.firstWhere((p) => p.label == '12h');
      expect(twelve.pricePkr, 5800);
      expect(twelve.enabled, isFalse);
    });

    test('use case rejects a vehicleId mismatch', () async {
      final ds = FleetRemoteDataSource();
      final repo = FleetRepositoryImpl(remoteDataSource: ds);
      final useCase = UpdateVehiclePricingUseCase(repo);
      expect(
        () => useCase(vehicleId: 'other-id', vehicle: testVehicle),
        throwsArgumentError,
      );
    });

    testWidgets('rate matrix renders packages and saves', (tester) async {
      bool saved = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerRateMatrixView(
            vehicle: testVehicle,
            onRatesSaved: () => saved = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Package rates'), findsOneWidget);
      expect(find.text('Honda Civic Oriel (2021)'), findsOneWidget);
      // 09b: seven package chips, one price row at a time; the
      // in-city list heading is unchanged.
      expect(find.text('In-City Rent Rates'), findsOneWidget);
      expect(find.text('12-Hour Half Day'), findsOneWidget);
      expect(find.text('Weekly Package (7 Days)'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      expect(find.text('Out-City Rent Rates'), findsOneWidget);
      expect(find.text('Applies to all packages'), findsOneWidget);
      expect(find.text('Out-of-City Daily (24h)'), findsOneWidget);
      expect(find.text('Extra Hour Charge'), findsOneWidget);
      // Worker A (2026-11-21): the per-car driver surcharge editor
      // is gone — the rate is shop-scoped in booking settings.
      expect(find.text('With-Driver Surcharge (per day)'), findsNothing);
      expect(find.text('Per KM Pricing?'), findsOneWidget);
      expect(find.text('Self-Drive Allowed'), findsOneWidget);
      // Deposit / advance / fuel policy moved to the 010b rules
      // screen — they are no longer on the rates editor.
      expect(find.text('Security'), findsNothing);
      expect(find.text('Fuel Policy'), findsNothing);
      expect(find.text('Pricing Policy'), findsNothing);

      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
    });
  });

  group('Phase B (B2) — package picker with a real vehicle', () {
    testWidgets('shows only enabled packages at real prices', (tester) async {
      Map<String, dynamic>? draft;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RentPackagePickerView(
            carId: 'veh-pkg-1',
            carName: 'Honda Civic Oriel',
            plateNumber: 'LEA-4820',
            shopId: 'shop-1',
            shopName: 'Test Shop',
            dailySelfDriveRate: 9000,
            dailyWithDriverRate: 10500,
            hourlyRate: 1500,
            vehicle: testVehicle,
            onProceedToReview: (d) => draft = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Rental Package'), findsOneWidget);
      expect(find.text('Daily 24-Hours'), findsOneWidget);
      expect(find.text('12-Hour Half Day'), findsOneWidget);
      expect(find.text('Weekly Package'), findsOneWidget);
      // The disabled 3h package is hidden.
      expect(find.text('3-Hour Quick Trip'), findsNothing);
      // 24h selected by default, 1 day, self-drive: Rs. 9,000.
      expect(find.text('Total: Rs. 9,000'), findsOneWidget);
      expect(find.text('Advance Due: Rs. 3,000'), findsOneWidget);
      expect(find.text('Security: Rs. 20,000'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(draft, isNotNull);
      expect(draft!['packageType'], '24h');
      expect(draft!['packageHours'], 24);
      expect(draft!['totalAmount'], 9000);
      expect(draft!['advanceRequired'], 3000);
      expect(draft!['securityDepositPkr'], 20000);
    });

    testWidgets('with-driver adds the surcharge to the total',
        (tester) async {
      Map<String, dynamic>? draft;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RentPackagePickerView(
            carId: 'veh-pkg-1',
            carName: 'Honda Civic Oriel',
            plateNumber: 'LEA-4820',
            shopId: 'shop-1',
            shopName: 'Test Shop',
            dailySelfDriveRate: 9000,
            dailyWithDriverRate: 10500,
            hourlyRate: 1500,
            vehicle: testVehicle,
            driverRatePerDayPkr: 1500,
            onProceedToReview: (d) => draft = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('With Chauffeur'));
      await tester.pumpAndSettle();

      // 24h (9000) + one day of driver surcharge (1500).
      expect(find.text('Total: Rs. 10,500'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(draft!['isWithDriver'], isTrue);
      expect(draft!['totalAmount'], 10500);
    });
  });

  group('Phase B (B2) — counter booking totals', () {
    test('totalFor prices the package, not a typed number', () {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      final pkg6 = testVehicle.packages.firstWhere((p) => p.label == '6h');
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: false,
        ),
        9000,
      );
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: true,
          driverRatePerDayPkr: 1500,
        ),
        10500,
      );
      // 6h with driver: 6000 + prorated 1500 * 6/24 = 6375.
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg6,
          isWithDriver: true,
          driverRatePerDayPkr: 1500,
        ),
        6375,
      );
      // Worker A (2026-11-21): without the shop setting the
      // vehicle's stored surcharge is ignored — no driver charge.
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: true,
        ),
        9000,
      );
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: null,
          package: pkg24,
          isWithDriver: false,
        ),
        0,
      );
    });
  });
}
