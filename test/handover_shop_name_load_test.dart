import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/utils/shop_name.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_wizard_cubit.dart';
import 'package:rentalhub/features/owner/presentation/services/handover_wizard_loader.dart';

// Repro for the build-89 phone report: at the handover wizard's
// last step, certifying is blocked with "Shop name could not be
// loaded. Retry the load before certifying the handover."
//
// Root cause (code): the handover shop-name read used
// `doc['name'] ?? doc['shopName']`, but live shop docs store the
// name under snake_case `shop_name` (ShopModel.toMap) — so the
// lookup always came back empty on real data, and the doc id was
// used raw (a bare owner UID never matches a `shop_<uid>` doc).

BookingEntity _booking({required String shopId, String? shopName}) =>
    BookingEntity(
      bookingId: 'RH-SHOPNAME-1',
      customerId: 'cust-1',
      shopId: shopId,
      shopName: shopName,
      vehicleId: 'veh-1',
      vehicleName: 'Honda Civic Oriel 2021',
      customerName: 'Ayesha Khan',
      customerPhone: '03001234567',
      customerCnic: '35202-1234567-1',
      packageType: '24h',
      pickupTime: DateTime.now(),
      returnTime: DateTime.now().add(const Duration(days: 1)),
      totalAmount: 9000,
      advancePaid: 1000,
      advanceRequired: 1000,
      remainingBalance: 8000,
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('shopNameFromData', () {
    test('reads snake_case shop_name first', () {
      expect(
        shopNameFromData({
          'shop_name': 'Meezan Rent a Car',
          'name': 'Wrong',
          'shopName': 'Wrong',
        }),
        'Meezan Rent a Car',
      );
    });

    test('falls back to legacy name / shopName keys', () {
      expect(shopNameFromData({'name': 'Legacy Shop'}), 'Legacy Shop');
      expect(shopNameFromData({'shopName': 'Camel Shop'}), 'Camel Shop');
    });

    test('absent or empty data yields an empty string', () {
      expect(shopNameFromData(null), '');
      expect(shopNameFromData({}), '');
      expect(shopNameFromData({'shop_name': ''}), '');
    });
  });

  group('HandoverWizardLoader.load — shop name', () {
    late FakeFirebaseFirestore fake;

    setUp(() async {
      fake = FakeFirebaseFirestore();
      await fake.collection('shops').doc('shop_owner123').set({
        'shop_id': 'shop_owner123',
        'owner_id': 'owner123',
        'shop_name': 'Meezan Rent a Car',
      });
    });

    test('loads shop_name from the canonical shop doc', () async {
      final loaded = await HandoverWizardLoader.load(
        booking: _booking(shopId: 'shop_owner123'),
        wizard: HandoverWizardCubit(bookingId: 'RH-SHOPNAME-1'),
        firestore: fake,
      );
      expect(loaded.shopName, 'Meezan Rent a Car');
    });

    test('loads shop_name when the booking carries the bare owner UID',
        () async {
      final loaded = await HandoverWizardLoader.load(
        booking: _booking(shopId: 'owner123'),
        wizard: HandoverWizardCubit(bookingId: 'RH-SHOPNAME-1'),
        firestore: fake,
      );
      expect(loaded.shopName, 'Meezan Rent a Car');
    });

    test('falls back to a legacy name field on the shop doc', () async {
      await fake.collection('shops').doc('shop_legacy').set({
        'shop_id': 'shop_legacy',
        'owner_id': 'legacy1',
        'name': 'Legacy Motors',
      });
      final loaded = await HandoverWizardLoader.load(
        booking: _booking(shopId: 'shop_legacy'),
        wizard: HandoverWizardCubit(bookingId: 'RH-SHOPNAME-1'),
        firestore: fake,
      );
      expect(loaded.shopName, 'Legacy Motors');
    });

    test('a prefilled booking shopName is kept without a fetch', () async {
      final loaded = await HandoverWizardLoader.load(
        booking: _booking(shopId: 'shop_owner123', shopName: 'Booked Name'),
        wizard: HandoverWizardCubit(bookingId: 'RH-SHOPNAME-1'),
        firestore: fake,
      );
      expect(loaded.shopName, 'Booked Name');
    });

    test('a shop doc with no name at all leaves the name empty', () async {
      await fake.collection('shops').doc('shop_noname').set({
        'shop_id': 'shop_noname',
        'owner_id': 'noname1',
      });
      final loaded = await HandoverWizardLoader.load(
        booking: _booking(shopId: 'shop_noname'),
        wizard: HandoverWizardCubit(bookingId: 'RH-SHOPNAME-1'),
        firestore: fake,
      );
      expect(loaded.shopName, '');
    });
  });
}
