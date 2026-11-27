import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pending offline creates must merge only into the list they were
/// queried by: a pending booking for customer A must never show in
/// customer B's "My Bookings", and the same across shops. Regression
/// cover for the vehicle-scoped fix (out-of-city picker, Phase B),
/// extended to the customer and shop reads, which used to merge
/// pending creates unfiltered.
void main() {
  late OfflineSyncQueue queue;
  late BookingRemoteDataSource ds;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    queue = OfflineSyncQueue(prefs: await SharedPreferences.getInstance());
    ds = BookingRemoteDataSource(syncQueue: queue);
  });

  Future<void> enqueuePending({
    required String bookingId,
    required String customerId,
    required String shopId,
    required String vehicleId,
  }) async {
    await queue.enqueue(
      kind: 'booking_create',
      entityId: bookingId,
      payload: {
        'bookingId': bookingId,
        'customerId': customerId,
        'shopId': shopId,
        'vehicleId': vehicleId,
        'status': 'requested',
      },
    );
  }

  group('pending offline creates are scoped to the queried list', () {
    test("customer A's pending booking does not leak into customer B",
        () async {
      await enqueuePending(
        bookingId: 'RH-pending-1',
        customerId: 'cust-A',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
      );

      final forB = await ds.getCustomerBookings('cust-B');
      expect(forB.map((b) => b.bookingId),
          isNot(contains('RH-pending-1')));

      final forA = await ds.getCustomerBookings('cust-A');
      expect(
          forA.map((b) => b.bookingId), contains('RH-pending-1'));
    });

    test("shop 1's pending booking does not leak into shop 2", () async {
      await enqueuePending(
        bookingId: 'RH-pending-2',
        customerId: 'cust-A',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
      );

      final forShop2 = await ds.getShopBookings('shop-2');
      expect(forShop2.map((b) => b.bookingId),
          isNot(contains('RH-pending-2')));

      final forShop1 = await ds.getShopBookings('shop-1');
      expect(forShop1.map((b) => b.bookingId), contains('RH-pending-2'));
    });

    test('vehicle scoping still holds', () async {
      await enqueuePending(
        bookingId: 'RH-pending-3',
        customerId: 'cust-A',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
      );

      final forVeh2 = await ds.getVehicleBookings('veh-2');
      expect(forVeh2.map((b) => b.bookingId),
          isNot(contains('RH-pending-3')));

      final forVeh1 = await ds.getVehicleBookings('veh-1');
      expect(forVeh1.map((b) => b.bookingId), contains('RH-pending-3'));
    });
  });
}
