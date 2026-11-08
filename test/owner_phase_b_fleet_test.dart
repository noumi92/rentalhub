import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/data/models/vehicle_model.dart';
import 'package:rentalhub/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:rentalhub/features/fleet/domain/usecases/add_vehicle_usecase.dart';
import 'package:rentalhub/features/fleet/domain/usecases/get_shop_vehicles_usecase.dart';
import 'package:rentalhub/features/fleet/domain/usecases/update_vehicle_pricing_usecase.dart';
import 'package:rentalhub/features/fleet/domain/usecases/update_vehicle_status_usecase.dart';
import 'package:rentalhub/features/fleet/presentation/cubit/fleet_cubit.dart';
import 'package:rentalhub/features/fleet/presentation/cubit/fleet_state.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// The local copy's PNG assets are corrupt (downloaded through the
// connector's text path), so any widget rendering a car photo throws
// "Invalid image data" locally while passing in CI. This bundle answers
// every image load with a valid 1x1 PNG so the view tests run green here.
class _TestAssetBundle extends AssetBundle {
  static final ByteData _pixel = ByteData.view(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ).buffer);

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      // Empty binary manifest (StandardMessageCodec-encoded map).
      return const StandardMessageCodec()
          .encodeMessage(<String, Object>{})!;
    }
    return _pixel;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '{}';
}

Widget _withTestAssets(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: DefaultAssetBundle(
      bundle: _TestAssetBundle(),
      child: child,
    ),
  );
}

// Owner Module Plan — Phase B (B1): fleet reads real vehicles through
// FleetCubit, the add-vehicle form saves a real VehicleEntity, and the
// availability toggle writes back. These tests run against the
// in-memory data-source fallback (no Firebase in tests).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Phase B (B1) — vehicle model', () {
    test('round-trips the new identity and pricing fields', () {
      const vehicle = VehicleModel(
        vehicleId: 'v-test-1',
        shopId: 'shop-1',
        make: 'Honda',
        model: 'Civic Oriel',
        year: 2021,
        plateNumber: 'LEA-4820',
        rates: VehicleRatesModel(daily24: 9000),
        color: 'Super White',
        mileageKm: 45200,
        chassisNumber: 'CHS123',
        engineNumber: 'ENG456',
        engineCc: 1800,
        features: ['ABS Brakes', 'GPS Tracking'],
        trackerProvider: 'TPL Trakker',
        insurancePolicy: 'EFU-2026-11',
        weeklyRate: 52000,
        securityDepositPkr: 25000,
        advanceRequiredPkr: 2000,
        extraHourPkr: 600,
        withDriverSurchargePkr: 2000,
        fuelPolicy: 'Same to Same',
        // Audit §5 (integration): the six extra-file URLs round-trip
        // too — they used to be uploaded but never stored.
        photoBackUrl: 'https://storage.example/back.jpg',
        photoSideUrl: 'https://storage.example/side.jpg',
        photoInteriorUrl: 'https://storage.example/interior.jpg',
        regBookUrl: 'https://storage.example/regbook.jpg',
        tokenTaxUrl: 'https://storage.example/tokentax.jpg',
        insuranceUrl: 'https://storage.example/insurance.jpg',
      );
      final restored = VehicleModel.fromMap(vehicle.toMap(), 'v-test-1');
      expect(restored, equals(vehicle));
      expect(restored.displayName, 'Honda Civic Oriel 2021');
    });

    test('toMap omits null optionals so old documents still read', () {
      const vehicle = VehicleModel(
        vehicleId: 'v-test-2',
        shopId: 'shop-1',
        make: 'Suzuki',
        model: 'Alto VXL',
        year: 2023,
        plateNumber: 'LHR-1029',
        rates: VehicleRatesModel(daily24: 3500),
      );
      final map = vehicle.toMap();
      expect(map.containsKey('color'), isFalse);
      expect(map.containsKey('chassisNumber'), isFalse);
      expect(map.containsKey('features'), isFalse);
      // Audit §5 (integration): the extra-file URL fields are omitted
      // when null, so old documents still read fine.
      expect(map.containsKey('photoBackUrl'), isFalse);
      expect(map.containsKey('photoSideUrl'), isFalse);
      expect(map.containsKey('photoInteriorUrl'), isFalse);
      expect(map.containsKey('regBookUrl'), isFalse);
      expect(map.containsKey('tokenTaxUrl'), isFalse);
      expect(map.containsKey('insuranceUrl'), isFalse);
      final restored = VehicleModel.fromMap(map, 'v-test-2');
      expect(restored.color, isNull);
      expect(restored.features, isEmpty);
    });

    test('copyWith keeps the new fields', () {
      const vehicle = VehicleModel(
        vehicleId: 'v-test-3',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla Grande',
        year: 2022,
        plateNumber: 'ICT-9912',
        rates: VehicleRatesModel(daily24: 8500),
        color: 'Silver',
      );
      final updated = vehicle.copyWith(status: 'maintenance');
      expect(updated.status, 'maintenance');
      expect(updated.color, 'Silver');
      expect(updated.plateNumber, 'ICT-9912');
    });
  });

  group('Phase B (B1) — status update', () {
    test('use case flips status and rejects anything else', () async {
      final ds = FleetRemoteDataSource();
      final repo = FleetRepositoryImpl(remoteDataSource: ds);
      final useCase = UpdateVehicleStatusUseCase(repo);

      await useCase(vehicleId: 'v1', status: 'maintenance');
      final cars = await repo.getShopVehicles('shop-basic');
      expect(
        cars.firstWhere((c) => c.vehicleId == 'v1').status,
        'maintenance',
      );

      expect(
        () => useCase(vehicleId: 'v1', status: 'rented'),
        throwsArgumentError,
      );
    });

    test('cubit loads seeded vehicles and toggles one', () async {
      final ds = FleetRemoteDataSource();
      final repo = FleetRepositoryImpl(remoteDataSource: ds);
      final cubit = FleetCubit(
        addVehicleUseCase: AddVehicleUseCase(repo),
        getShopVehiclesUseCase: GetShopVehiclesUseCase(repo),
        updateVehicleStatusUseCase: UpdateVehicleStatusUseCase(repo),
        updateVehiclePricingUseCase: UpdateVehiclePricingUseCase(repo),
      );

      await cubit.loadVehicles('shop-basic');
      expect(cubit.state, isA<FleetLoaded>());
      expect((cubit.state as FleetLoaded).vehicles.length, 3);

      await cubit.updateVehicleStatus(
        shopId: 'shop-basic',
        vehicleId: 'v2',
        status: 'maintenance',
      );
      final loaded = cubit.state as FleetLoaded;
      expect(
        loaded.vehicles
            .firstWhere((c) => c.vehicleId == 'v2')
            .status,
        'maintenance',
      );
      await cubit.close();
    });
  });

  group('Phase B (B1) — fleet view shows real vehicles', () {
    testWidgets('renders the seeded shop vehicles', (tester) async {
      await tester.pumpWidget(
        _withTestAssets(const OwnerFleetView(shopId: 'shop-basic')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fleet Management'), findsOneWidget);
      expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
      expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
      expect(find.text('Total Fleet'), findsOneWidget);
      expect(find.text('3 Cars'), findsOneWidget);
      expect(find.text('Al-Falah Rent a Car'), findsNothing);
    });

    testWidgets('shows an honest empty state for an unknown shop',
        (tester) async {
      await tester.pumpWidget(
        _withTestAssets(const OwnerFleetView(shopId: 'shop-empty')),
      );
      await tester.pumpAndSettle();

      expect(find.text('No vehicles yet — add your first car'), findsOneWidget);
      expect(find.text('Add Vehicle Now'), findsOneWidget);
    });
  });
}
