import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/usecases/add_vehicle_usecase.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Batch 3: Owner Fleet & Pricing Matrix CRUD Operations', () {
    late FleetRemoteDataSource dataSource;
    late AddVehicleUseCase addVehicleUseCase;

    setUp(() {
      dataSource = FleetRemoteDataSource();
      addVehicleUseCase = di.sl<AddVehicleUseCase>();
    });

    test('Add Vehicle: saves car to showroom fleet and increments count', () async {
      const newCar = VehicleEntity(
        vehicleId: 'veh-sonata-01',
        shopId: 'shop-1',
        make: 'Hyundai',
        model: 'Sonata 2.5',
        year: 2024,
        plateNumber: 'LE-24-111',
        category: 'Luxury',
        transmission: 'Automatic',
        fuelType: 'Petrol',
        rates: VehicleRatesEntity(
          hourly1: 2500,
          hourly3: 6500,
          hourly6: 12000,
          daily24: 20000,
          outOfCityDaily: 25000,
        ),
      );

      await dataSource.addVehicle(shopId: 'shop-1', vehicle: newCar);
      final cars = await dataSource.getShopVehicles('shop-1');
      expect(cars.any((c) => c.vehicleId == 'veh-sonata-01'), isTrue);
    });

    test('Update Vehicle Rates: modifies hourly and daily rates in store', () async {
      const updated = VehicleRatesEntity(
        hourly1: 1800,
        hourly3: 4000,
        hourly6: 7000,
        daily24: 10000,
        outOfCityDaily: 13000,
      );

      await dataSource.updateVehicleRates(
        vehicleId: 'v1',
        rates: updated,
      );

      final cars = await dataSource.getShopVehicles('shop-basic');
      final civic = cars.firstWhere((c) => c.vehicleId == 'v1');
      expect(civic.rates.daily24, equals(10000));
      expect(civic.rates.hourly1, equals(1800));
      expect(civic.rates.outOfCityDaily, equals(13000));
    });

    test('Update Vehicle Status: toggles between available, rented and maintenance', () async {
      await dataSource.updateVehicleStatus(
        vehicleId: 'v1',
        status: 'maintenance',
      );

      final cars = await dataSource.getShopVehicles('shop-basic');
      final civic = cars.firstWhere((c) => c.vehicleId == 'v1');
      expect(civic.status, equals('maintenance'));
    });

    test('Freemium 3-Car Usage Guard: blocks 4th car for basic tier shop', () async {
      const fourthCar = VehicleEntity(
        vehicleId: 'v4',
        shopId: 'shop-basic',
        make: 'Kia',
        model: 'Sportage',
        year: 2023,
        plateNumber: 'LHR-9988',
        rates: VehicleRatesEntity(daily24: 12000),
      );

      // shop-basic already has 3 vehicles (v1, v2, v3), so 4th must fail
      expect(
        () => addVehicleUseCase(
          shopId: 'shop-basic',
          vehicle: fourthCar,
        ),
        throwsA(isA<BusinessRuleException>()),
      );
    });
  });

  group('Batch 3: Screen UI Actions & Rendering Tests', () {
    testWidgets('OwnerRateMatrixView: renders package chips, drive-mode switches and saves the package', (tester) async {
      bool saved = false;
      const testCar = VehicleEntity(
        vehicleId: 'veh-civic-matrix',
        shopId: 'shop-1',
        make: 'Honda',
        model: 'Civic RS Turbo',
        year: 2023,
        plateNumber: 'LEA-24-500',
        rates: VehicleRatesEntity(
          hourly1: 1500,
          hourly3: 3500,
          hourly6: 6000,
          daily24: 8500,
          outOfCityDaily: 11000,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerRateMatrixView(
            vehicle: testCar,
            onRatesSaved: () => saved = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Package rates'), findsOneWidget);
      expect(find.text('Honda Civic RS Turbo (2023)'), findsOneWidget);
      expect(find.text('Self-Drive Allowed'), findsOneWidget);
      expect(find.text('Chauffeur Service Allowed'), findsOneWidget);
      expect(find.text('In-City Rent Rates'), findsOneWidget);
      expect(find.text('Out-City Rent Rates'), findsOneWidget);
      expect(find.text('Applies to all packages'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      // The daily label appears twice: its chip AND its price row.
      expect(find.text('In-City Daily (24h)'), findsWidgets);
      expect(find.text('Out-of-City Daily (24h)'), findsOneWidget);

      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
    });

    testWidgets('OwnerFleetView: renders fleet vehicles and triggers add navigation', (tester) async {
      bool tappedAdd = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerFleetView(
            onAddVehicle: () => tappedAdd = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fleet Management'), findsOneWidget);
      expect(find.byTooltip('Add Vehicle'), findsOneWidget);

      await tester.tap(find.byTooltip('Add Vehicle'));
      await tester.pumpAndSettle();

      expect(tappedAdd, isTrue);
    });
  });
}
