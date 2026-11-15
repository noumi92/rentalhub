// Shop-id mismatch (2026-11-15, rulebook D12): owner triage reads
// bookings by the signed-in owner's bare UID while customer bookings
// carry the shop DOCUMENT id (shop_<uid>). These tests pin the
// bookings-side fix against FakeFirebaseFirestore: the triage stream
// and the shop list match both id forms, and walk-in bookings are
// written with the document id.
//
// The walk-in test signs in nobody, so currentShopId() falls back to
// 'shop-1'; the seeded shop doc (shop_shop-1, owner_id shop-1) makes
// that the canonical id the service must resolve to.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/services/walk_in_booking_service.dart';

const _uidAhmed = 'uid-ahmed';
const _shopAhmed = 'shop_uid-ahmed';
const _uidMeezan = 'uid-meezan';
const _shopMeezan = 'shop_uid-meezan';

Map<String, dynamic> _bookingDoc({
  required String shopId,
  String customerId = 'cust-1',
  String vehicleId = 'veh-1',
  String status = 'requested',
}) {
  final pickup = DateTime(2026, 11, 14, 10);
  return {
    'customerId': customerId,
    'shopId': shopId,
    'vehicleId': vehicleId,
    'packageType': '24h',
    'isWithDriver': false,
    'pickupTime': pickup.toIso8601String(),
    'returnTime': pickup.add(const Duration(days: 1)).toIso8601String(),
    'totalAmount': 7500,
    'advanceRequired': 2000,
    'advancePaid': 0,
    'remainingBalance': 7500,
    'status': status,
  };
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 100));

const _walkInVehicle = VehicleEntity(
  vehicleId: 'veh-walkin-1',
  shopId: 'shop-1',
  make: 'Toyota',
  model: 'Corolla Altis Grande',
  year: 2023,
  plateNumber: 'LEA-24-4096',
  rates: VehicleRatesEntity(
    hourly1: 1500,
    hourly3: 3500,
    hourly6: 6000,
    daily24: 7500,
    outOfCityDaily: 9500,
  ),
  weeklyRate: 45000,
  securityDepositPkr: 20000,
  advanceRequiredPkr: 2000,
  extraHourPkr: 600,
  withDriverSurchargePkr: 1500,
  fuelPolicy: 'Same to Same',
  packages: [
    VehiclePackageEntity(
        label: '24h', hours: 24, pricePkr: 7500, kmIncluded: 250),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('triage reads resolve both shop-id forms', () {
    late FakeFirebaseFirestore fake;
    late BookingRemoteDataSource ds;

    setUp(() async {
      fake = FakeFirebaseFirestore();
      await fake.collection('shops').doc(_shopAhmed).set({
        'shop_name': 'Al-Falah Rent a Car',
        'owner_id': _uidAhmed,
        'verification_status': 'approved',
        'is_verified': true,
        'city': 'Lahore',
      });
      await fake.collection('shops').doc(_shopMeezan).set({
        'shop_name': 'Meezan Rent a Car',
        'owner_id': _uidMeezan,
        'verification_status': 'approved',
        'is_verified': true,
        'city': 'Karachi',
      });
      // The live case: a customer booking written with the shop
      // DOCUMENT id (RH-613236-0 on Al-Falah).
      await fake
          .collection('bookings')
          .doc('RH-613236-0')
          .set(_bookingDoc(shopId: _shopAhmed));
      // The legacy form: a walk-in written with the bare UID.
      await fake
          .collection('bookings')
          .doc('RH-uid-form')
          .set(_bookingDoc(shopId: _uidAhmed, vehicleId: 'veh-2'));
      // Another shop's booking: must never leak in.
      await fake
          .collection('bookings')
          .doc('RH-other')
          .set(_bookingDoc(shopId: _shopMeezan, vehicleId: 'veh-3'));
      ds = BookingRemoteDataSource(firestore: fake);
    });

    test('streamShopBookings by bare UID shows the doc-id booking',
        () async {
      final seen = <List<BookingEntity>>[];
      final sub = ds.streamShopBookings(_uidAhmed).listen(seen.add);
      await _settle();
      expect(seen, isNotEmpty);
      final ids =
          seen.last.map((b) => b.bookingId).toSet();
      expect(ids, containsAll({'RH-613236-0', 'RH-uid-form'}));
      expect(ids, isNot(contains('RH-other')));
      await sub.cancel();
    });

    test('streamShopBookings by doc id shows the same bookings',
        () async {
      final seen = <List<BookingEntity>>[];
      final sub = ds.streamShopBookings(_shopAhmed).listen(seen.add);
      await _settle();
      expect(seen, isNotEmpty);
      final ids =
          seen.last.map((b) => b.bookingId).toSet();
      expect(ids, containsAll({'RH-613236-0', 'RH-uid-form'}));
      expect(ids, isNot(contains('RH-other')));
      await sub.cancel();
    });

    test('getShopBookings by bare UID returns both id forms',
        () async {
      final list = await ds.getShopBookings(_uidAhmed);
      final ids = list.map((b) => b.bookingId).toSet();
      expect(ids, containsAll({'RH-613236-0', 'RH-uid-form'}));
      expect(ids, isNot(contains('RH-other')));
    });

    test('getShopBookings by doc id returns the same set', () async {
      final list = await ds.getShopBookings(_shopAhmed);
      final ids = list.map((b) => b.bookingId).toSet();
      expect(ids, containsAll({'RH-613236-0', 'RH-uid-form'}));
      expect(ids, isNot(contains('RH-other')));
    });

    test('canonicalShopIdFor resolves the UID to the document id',
        () async {
      expect(await ds.canonicalShopIdFor(_uidAhmed), _shopAhmed);
      expect(await ds.canonicalShopIdFor(_shopAhmed), _shopAhmed);
      // A legacy shop whose doc id IS the UID resolves to itself.
      expect(await ds.canonicalShopIdFor('uid-legacy'), 'uid-legacy');
    });
  });

  group('walk-in writes carry the shop document id', () {
    late FakeFirebaseFirestore fake;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues(
          {'rentalhub_locked_role': 'owner'});
      await di.initDependencies();
    });

    setUp(() async {
      fake = FakeFirebaseFirestore();
      // The fallback shop id in tests is 'shop-1' (nobody signed
      // in); its proper doc is shop_shop-1, owned by 'shop-1'.
      await fake.collection('shops').doc('shop_shop-1').set({
        'shop_name': 'Test Shop',
        'owner_id': 'shop-1',
        'verification_status': 'approved',
        'is_verified': true,
        'city': 'Lahore',
      });
      di.sl.unregister<BookingRemoteDataSource>();
      di.sl.registerSingleton<BookingRemoteDataSource>(
        BookingRemoteDataSource(firestore: fake),
      );
    });

    test('a walk-in booking is stored with the document id', () async {
      final pkg24 = _walkInVehicle.packages
          .firstWhere((p) => p.label == '24h');
      final created = await WalkInBookingService.createWalkInBooking(
        name: 'Counter Customer',
        phone: '03001234567',
        cnic: '35202-1234567-1',
        guarantor: null,
        vehicle: _walkInVehicle,
        package: pkg24,
        isWithDriver: false,
        rentAmount: 7500,
        advanceRequired: 2000,
        pickupTime: DateTime(2026, 11, 15, 10),
        returnTime: DateTime(2026, 11, 16, 10),
        tripType: 'in_city',
        advanceReceived: 0,
      );
      expect(created.shopId, 'shop_shop-1');
      final stored = (await fake
              .collection('bookings')
              .doc(created.bookingId)
              .get())
          .data();
      expect(stored, isNotNull);
      expect(stored!['shopId'], 'shop_shop-1');
      // And the owner's triage read (by the bare UID) now sees it.
      final ds = di.sl<BookingRemoteDataSource>();
      final triage = await ds.getShopBookings('shop-1');
      expect(triage.map((b) => b.bookingId),
          contains(created.bookingId));
    });
  });
}
