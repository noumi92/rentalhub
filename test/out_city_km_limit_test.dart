import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/presentation/widgets/package_tier_list.dart';
import 'package:rentalhub/features/fleet/data/models/vehicle_model.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:rentalhub/features/fleet/domain/usecases/update_vehicle_pricing_usecase.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Out-of-city km limit (user decision 2026-11-09): 300 km/day,
// editable per vehicle on the 09b rates screen. The 300 is only a
// fallback where a vehicle has no stored value — existing documents
// keep their stored value (350, or anything else) with no migration.
class _FakeFleetRepository implements FleetRepository {
  String? savedPricingId;
  VehicleEntity? savedPricing;

  @override
  Future<int> getActiveVehicleCount(String shopId) async => 0;

  @override
  Future<String> getShopSubscriptionTier(String shopId) async => 'basic';

  @override
  Future<List<VehicleEntity>> getShopVehicles(String shopId) async => [];

  @override
  Future<void> addVehicle({
    required String shopId,
    required VehicleEntity vehicle,
  }) async {}

  @override
  Future<void> updateVehicleStatus({
    required String vehicleId,
    required String status,
  }) async {}

  @override
  Future<void> updateVehiclePricing({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) async {
    savedPricingId = vehicleId;
    savedPricing = vehicle;
  }

  @override
  Future<void> updateVehicleDetails({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) async {}
}

const _packages = [
  VehiclePackageEntity(label: '1h', hours: 1, pricePkr: 1000, kmIncluded: 15),
  VehiclePackageEntity(label: '6h', hours: 6, pricePkr: 4000, kmIncluded: 80),
  VehiclePackageEntity(label: '24h', hours: 24, pricePkr: 7000, kmIncluded: 250),
  VehiclePackageEntity(label: 'Weekly', hours: 168, pricePkr: 42000, kmIncluded: 1750),
  VehiclePackageEntity(label: 'Monthly', hours: 720, pricePkr: 168000, kmIncluded: 7500),
];

VehicleEntity _vehicle({int? outOfCityKmPerDay, String? outCityMode, int? outCityPerKmPkr}) {
  return VehicleEntity(
    vehicleId: 'veh-km-300',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla GLi',
    year: 2022,
    plateNumber: 'LEA-22-7000',
    rates: const VehicleRatesEntity(
      hourly1: 1000,
      hourly3: 2500,
      hourly6: 4000,
      daily24: 7000,
      outOfCityDaily: 9500,
    ),
    weeklyRate: 42000,
    monthlyRate: 168000,
    extraKmPkr: 25,
    withDriverSurchargePkr: 1500,
    outOfCityKmPerDay: outOfCityKmPerDay,
    packages: _packages,
    outCityMode: outCityMode,
    outCityPerKmPkr: outCityPerKmPkr,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('kDefaultOutCityKmPerDay', () {
    test('is 300 km/day', () {
      expect(kDefaultOutCityKmPerDay, 300);
    });
  });

  group('fare path — 300 default when nothing is stored', () {
    List<PackageTierOption> options(VehicleEntity v) => PackageTierList.optionsFor(
          vehicle: v,
          isWithDriver: false,
          dailySelfDriveRate: 7000,
          dailyWithDriverRate: 8500,
          hourlyRate: 1000,
          isOutOfCity: true,
        );

    test('per-day mode shows a 300 km/day allowance', () {
      final daily = options(_vehicle()).firstWhere((o) => o.label == '24h');
      expect(daily.price, 9500);
      expect(daily.kmIncluded, '300 km/day');
      expect(daily.perKmRatePkr, isNull);
    });

    test('per-km estimate is built on 300 km/day', () {
      final opts = options(_vehicle(outCityMode: 'perKm', outCityPerKmPkr: 30));
      final daily = opts.firstWhere((o) => o.label == '24h');
      // 30 Rs/km × 300 km/day × 24h/24.
      expect(daily.price, 9000);
      expect(daily.perKmRatePkr, 30);
      expect(daily.perKmKmPerDay, 300);
      expect(daily.kmIncluded, '300 km');
      // 6h prorates the same allowance: 30 × 300 × 6/24.
      final six = opts.firstWhere((o) => o.label == '6h');
      expect(six.price, 2250);
      expect(six.perKmKmPerDay, 300);
    });

    test('a stored value still wins over the default', () {
      final opts = options(_vehicle(outCityMode: 'perKm', outCityPerKmPkr: 30, outOfCityKmPerDay: 350));
      final daily = opts.firstWhere((o) => o.label == '24h');
      expect(daily.price, 10500);
      expect(daily.perKmKmPerDay, 350);
      expect(daily.kmIncluded, '350 km');
    });
  });

  group('model round-trip — no migration, no backfill', () {
    test('an unset allowance is not written and reads back unset', () {
      final model = VehicleModel.fromEntity(_vehicle());
      expect(model.toMap().containsKey('outOfCityKmPerDay'), isFalse);
      final restored = VehicleModel.fromMap(model.toMap(), 'veh-km-300');
      expect(restored.outOfCityKmPerDay, isNull);
    });

    test('a stored 350 survives the round-trip unchanged', () {
      final model = VehicleModel.fromEntity(_vehicle(outOfCityKmPerDay: 350));
      final restored = VehicleModel.fromMap(model.toMap(), 'veh-km-300');
      expect(restored.outOfCityKmPerDay, 350);
      expect(restored.toMap(), model.toMap());
    });

    test('an edited 280 survives the round-trip unchanged', () {
      final model = VehicleModel.fromEntity(_vehicle(outOfCityKmPerDay: 280));
      final restored = VehicleModel.fromMap(model.toMap(), 'veh-km-300');
      expect(restored.outOfCityKmPerDay, 280);
    });
  });

  group('UpdateVehiclePricingUseCase — km round-trip', () {
    test('an edited km value reaches the repository', () async {
      final repo = _FakeFleetRepository();
      final edited = _vehicle().copyWith(outOfCityKmPerDay: 280);
      await UpdateVehiclePricingUseCase(repo)(
        vehicleId: 'veh-km-300',
        vehicle: edited,
      );
      expect(repo.savedPricingId, 'veh-km-300');
      expect(repo.savedPricing?.outOfCityKmPerDay, 280);
    });

    test('an unset value passes through as null (no backfill)', () async {
      final repo = _FakeFleetRepository();
      await UpdateVehiclePricingUseCase(repo)(
        vehicleId: 'veh-km-300',
        vehicle: _vehicle(),
      );
      expect(repo.savedPricing?.outOfCityKmPerDay, isNull);
    });
  });

  group('09b rates editor — km field edits and saves', () {
    Future<void> pumpEditor(WidgetTester tester, {VoidCallback? onSaved}) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerRateMatrixView(vehicle: _vehicle(), onRatesSaved: onSaved),
        ),
      );
      await tester.pumpAndSettle();
    }

    bool fieldShows(WidgetTester tester, String value) =>
        tester.widgetList<TextField>(find.byType(TextField)).any((f) => f.controller?.text == value);

    Future<void> tapModeSegment(WidgetTester tester, String label) async {
      final finder = find.text(label).first;
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('a vehicle with no stored value shows the 300 default', (tester) async {
      await pumpEditor(tester);
      expect(fieldShows(tester, '300'), isTrue);
      // The 300 is the km allowance, not a price: the daily rate is 9500.
      expect(find.text('300 km included + tracker cleared'), findsOneWidget);
    });

    testWidgets('editing the km field saves it through the pricing use case', (tester) async {
      final repo = di.sl<FleetRepository>();
      await repo.addVehicle(shopId: 'shop-1', vehicle: _vehicle());
      bool saved = false;
      await pumpEditor(tester, onSaved: () => saved = true);

      TextField fieldWithText(String value) =>
          tester.widgetList<TextField>(find.byType(TextField)).firstWhere((f) => f.controller?.text == value);
      final kmField = fieldWithText('300');
      await tester.ensureVisible(find.byWidget(kmField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byWidget(kmField), '280');
      await tester.pumpAndSettle();

      // The per-km estimate note follows the edited value.
      await tapModeSegment(tester, 'Per km');
      expect(find.text('Estimated on 280 km — final total on actual km at return'), findsOneWidget);

      await tapModeSegment(tester, 'Per day');
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);

      final cars = await repo.getShopVehicles('shop-1');
      final stored = cars.firstWhere((c) => c.vehicleId == 'veh-km-300');
      expect(stored.outOfCityKmPerDay, 280);
      // Nothing else moved: the daily mirror is untouched.
      expect(stored.rates.outOfCityDaily, 9500);
    });
  });
}
