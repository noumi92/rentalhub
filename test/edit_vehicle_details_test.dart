import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:rentalhub/features/fleet/domain/usecases/update_vehicle_usecase.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_edit_vehicle_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Car-details edit (Worker C): widget tests for the single flat form.
// Pure widget tests — the use case runs against a fake repository, no
// Firestore, no photo upload (no photo is picked in these tests).
class _FakeFleetRepository implements FleetRepository {
  String? savedDetailsId;
  VehicleEntity? savedDetails;

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
  }) async {}

  @override
  Future<void> updateVehicleDetails({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) async {
    savedDetailsId = vehicleId;
    savedDetails = vehicle;
  }
}

class _TestAssetBundle extends AssetBundle {
  static final ByteData _pixel = ByteData.view(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ).buffer);

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec()
          .encodeMessage(<String, Object>{})!;
    }
    return _pixel;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '{}';
}

const _vehicle = VehicleEntity(
  vehicleId: 'v-1',
  shopId: 'shop-1',
  make: 'Toyota',
  model: 'Corolla Grande',
  year: 2022,
  plateNumber: 'LEA-23-4567',
  rates: VehicleRatesEntity(daily24: 8500, outOfCityDaily: 10500),
);

// The plate field is a plain TextField, but TextFormField (model,
// color) also builds an inner TextField — so match the plate by its
// unique hint text instead of by type.
final _plateField = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'e.g. LEA-23-4567',
);

void main() {
  late _FakeFleetRepository fake;
  var popped = false;

  Future<void> pumpEdit(WidgetTester tester, {VehicleEntity vehicle = _vehicle}) async {
    // The form is long; a tall test viewport keeps every field (incl.
    // the status dropdown) on-screen without scrolling games.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: Scaffold(
            body: OwnerEditVehicleView(
              vehicle: vehicle,
              onBack: () => popped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    fake = _FakeFleetRepository();
    popped = false;
    sl.registerSingleton<FleetRepository>(fake);
    sl.registerSingleton<UpdateVehicleUseCase>(UpdateVehicleUseCase(fake));
  });

  tearDown(() async {
    await sl.reset();
  });

  group('OwnerEditVehicleView', () {
    testWidgets('form prefills from the vehicle', (tester) async {
      await pumpEdit(tester);
      expect(find.text('Edit car details'), findsOneWidget);
      expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
      // Model is the first TextFormField (color is the second); the
      // plate is matched by its hint text (see _plateField).
      expect(tester.widget<TextFormField>(find.byType(TextFormField).first).initialValue, 'Corolla Grande');
      expect(tester.widget<TextField>(_plateField).controller?.text, 'LEA-23-4567');
      final status = tester.widget<DropdownButton<String>>(find.byKey(const Key('edit-vehicle-status')));
      expect(status.value, 'available');
      expect(status.onChanged, isNotNull);
    });

    testWidgets('editing model, plate and status saves the updated entity', (tester) async {
      await pumpEdit(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Corolla Cross');
      await tester.enterText(_plateField, 'LEA-23-9999');
      await tester.tap(find.byKey(const Key('edit-vehicle-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maintenance').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save details'));
      await tester.pumpAndSettle();
      expect(fake.savedDetailsId, 'v-1');
      expect(fake.savedDetails?.model, 'Corolla Cross');
      expect(fake.savedDetails?.plateNumber, 'LEA-23-9999');
      expect(fake.savedDetails?.status, 'maintenance');
      // Rates ride along untouched — this screen never edits pricing.
      expect(fake.savedDetails?.rates.daily24, 8500);
      expect(fake.savedDetails?.make, 'Toyota');
      expect(popped, isTrue);
    });

    testWidgets('invalid plate blocks save', (tester) async {
      await pumpEdit(tester);
      await tester.enterText(_plateField, 'BAD');
      await tester.tap(find.text('Save details'));
      await tester.pumpAndSettle();
      expect(fake.savedDetails, isNull);
      expect(find.text('Registration plate number is required.'), findsOneWidget);
      expect(popped, isFalse);
    });

    testWidgets('empty model blocks save', (tester) async {
      await pumpEdit(tester);
      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tester.tap(find.text('Save details'));
      await tester.pumpAndSettle();
      expect(fake.savedDetails, isNull);
      expect(find.text('Please specify vehicle model variant.'), findsOneWidget);
      expect(popped, isFalse);
    });

    testWidgets('rented car has the status control disabled', (tester) async {
      const rented = VehicleEntity(
        vehicleId: 'v-2',
        shopId: 'shop-1',
        make: 'Honda',
        model: 'Civic Oriel',
        year: 2021,
        plateNumber: 'ICT-9912',
        status: 'rented',
        rates: VehicleRatesEntity(daily24: 9000, outOfCityDaily: 11500),
      );
      await pumpEdit(tester, vehicle: rented);
      final status = tester.widget<DropdownButton<String>>(find.byKey(const Key('edit-vehicle-status')));
      expect(status.value, 'rented');
      expect(status.onChanged, isNull);
      expect(find.text('On Rent'), findsOneWidget);
    });
  });
}
