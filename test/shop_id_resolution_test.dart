// Shop-id mismatch (2026-11-11, rulebook D12): repository tests run
// against FakeFirebaseFirestore. The owner app writes vehicles with
// shopId = the owner's UID while the customer app reads by shop DOCUMENT
// id; these tests pin the resolution in FleetRemoteDataSource — reads
// match both id forms, writes land with the document id, and the legacy
// shop (doc id == UID, no owner_id) keeps working.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/data/models/vehicle_model.dart';
import 'package:rentalhub/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/usecases/add_vehicle_usecase.dart';
import 'package:rentalhub/features/owner/presentation/services/subscription_data_source.dart';

const _uidAhmed = 'uid-ahmed';
const _shopAhmed = 'shop_uid-ahmed';
const _uidLegacy = 'uid-legacy';
const _uidMeezan = 'uid-meezan';
const _shopMeezan = 'shop_uid-meezan';

Map<String, dynamic> _vehicleDoc({
  required String shopId,
  required String make,
  required String model,
  required String plate,
  required int daily24,
}) {
  return {
    'shopId': shopId,
    'make': make,
    'model': model,
    'year': 2023,
    'plateNumber': plate,
    'category': 'Sedan',
    'transmission': 'Automatic',
    'fuelType': 'Petrol',
    'seats': 5,
    'isSelfDriveAvailable': true,
    'isWithDriverAvailable': true,
    'rates': {'daily_24': daily24},
    'status': 'available',
    'perKmPricingEnabled': true,
  };
}

VehicleEntity _vehicle({
  required String id,
  required String shopId,
  String plate = 'LEA-24-0001',
}) {
  return VehicleEntity(
    vehicleId: id,
    shopId: shopId,
    make: 'Toyota',
    model: 'Corolla Altis Grande',
    year: 2023,
    plateNumber: plate,
    rates: const VehicleRatesModel(daily24: 7500),
  );
}

void main() {
  late FakeFirebaseFirestore fake;
  late FleetRemoteDataSource ds;

  setUp(() async {
    fake = FakeFirebaseFirestore();
    // Owner Ahmed: BOTH a legacy shop doc (id == UID, no owner_id) and
    // a proper shop doc (id shop_<uid>, owner_id == UID).
    await fake.collection('shops').doc(_uidAhmed).set({
      'name': 'Al Barakah Rent A Car',
      'city': 'Karachi',
    });
    await fake.collection('shops').doc(_shopAhmed).set({
      'shop_name': 'Al-Falah Rent a Car',
      'owner_id': _uidAhmed,
      'verification_status': 'approved',
      'is_verified': true,
      'city': 'Lahore',
    });
    // Owner Meezan: proper shop doc only.
    await fake.collection('shops').doc(_shopMeezan).set({
      'shop_name': 'Meezan Rent a Car',
      'owner_id': _uidMeezan,
      'verification_status': 'approved',
      'is_verified': false,
      'city': 'Karachi',
    });
    // Legacy-only owner: a single shop doc whose id IS the UID.
    await fake.collection('shops').doc(_uidLegacy).set({
      'name': 'Legacy Rent A Car',
      'city': 'Islamabad',
    });
    // Ahmed's cars: one stored under the doc id (new/seeded form), one
    // under the UID (old app versions wrote the UID).
    await fake.collection('vehicles').doc('v-doc').set(_vehicleDoc(
        shopId: _shopAhmed,
        make: 'Toyota',
        model: 'Corolla Altis Grande',
        plate: 'LEA-23-4567',
        daily24: 7500));
    await fake.collection('vehicles').doc('v-uid').set(_vehicleDoc(
        shopId: _uidAhmed,
        make: 'Honda',
        model: 'Civic',
        plate: 'LEA-24-1024',
        daily24: 6500));
    await fake.collection('vehicles').doc('v-legacy').set(_vehicleDoc(
        shopId: _uidLegacy,
        make: 'Suzuki',
        model: 'Alto VXL',
        plate: 'LHR-24-3072',
        daily24: 3500));
    ds = FleetRemoteDataSource(firestore: fake);
  });

  test('customer read by doc id finds doc-id cars and UID-written cars',
      () async {
    final cars = await ds.getShopVehicles(_shopAhmed);
    final ids = cars.map((v) => v.vehicleId).toSet();
    expect(ids, containsAll({'v-doc', 'v-uid'}));
    expect(ids, isNot(contains('v-legacy')));
  });

  test('owner read by UID finds the same fleet', () async {
    final cars = await ds.getShopVehicles(_uidAhmed);
    final ids = cars.map((v) => v.vehicleId).toSet();
    expect(ids, containsAll({'v-doc', 'v-uid'}));
  });

  test('owner-added car lands with the shop document id', () async {
    await ds.addVehicle(
      shopId: _uidMeezan,
      vehicle: _vehicle(id: 'v-new', shopId: _uidMeezan),
    );
    final stored =
        (await fake.collection('vehicles').doc('v-new').get()).data();
    expect(stored, isNotNull);
    expect(stored!['shopId'], _shopMeezan);
    final byDoc = await ds.getShopVehicles(_shopMeezan);
    expect(byDoc.map((v) => v.vehicleId), contains('v-new'));
    final byUid = await ds.getShopVehicles(_uidMeezan);
    expect(byUid.map((v) => v.vehicleId), contains('v-new'));
  });

  test('legacy UID shop still resolves and writes under the UID', () async {
    final cars = await ds.getShopVehicles(_uidLegacy);
    expect(cars.map((v) => v.vehicleId), contains('v-legacy'));
    await ds.addVehicle(
      shopId: _uidLegacy,
      vehicle: _vehicle(id: 'v-legacy-new', shopId: _uidLegacy),
    );
    final stored =
        (await fake.collection('vehicles').doc('v-legacy-new').get()).data();
    expect(stored, isNotNull);
    expect(stored!['shopId'], _uidLegacy);
  });

  test('customer read does not leak other shops’ cars', () async {
    final cars = await ds.getShopVehicles(_shopMeezan);
    expect(cars, isEmpty);
  });

  test('free-tier cap counts doc-id cars, not just UID cars', () async {
    expect(await ds.getActiveVehicleCount(_uidAhmed), 2);
    expect(await ds.getActiveVehicleCount(_shopAhmed), 2);
    expect(await ds.getActiveVehicleCount(_uidLegacy), 1);
    // A free-tier owner with 3 doc-id cars cannot add a 4th.
    for (var i = 0; i < 3; i++) {
      await fake.collection('vehicles').doc('v-cap-$i').set(_vehicleDoc(
          shopId: _shopMeezan,
          make: 'Toyota',
          model: 'Corolla Altis Grande',
          plate: 'LEA-24-900$i',
          daily24: 7500));
    }
    final useCase =
        AddVehicleUseCase(FleetRepositoryImpl(remoteDataSource: ds));
    await expectLater(
      useCase(
          shopId: _uidMeezan,
          vehicle: _vehicle(id: 'v-cap-4', shopId: _uidMeezan)),
      throwsA(isA<BusinessRuleException>()),
    );
  });

  test('subscription fleet count matches both id forms', () async {
    final subs = SubscriptionDataSource(firestore: fake);
    expect(await subs.getFleetCount(_uidAhmed), 2);
    expect(await subs.getFleetCount(_shopAhmed), 2);
    expect(await subs.getFleetCount(_uidLegacy), 1);
  });
}
