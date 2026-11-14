import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/network/firestore_service.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/data/services/customer_home_service.dart';
import 'package:rentalhub/features/customer/data/services/customer_wallet_service.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/trust/data/datasources/kyc_remote_data_source.dart';

// Live updates (Item 2): a booking submitted (or re-statused by
// the owner) must reach every subscribed list without a reload.
// These tests drive the in-memory fallback — no Firebase app — so
// the data source's change feed is what re-emits, exactly like the
// offline path in production.

Future<BookingEntity> _submit(
  BookingRemoteDataSource ds, {
  String customerId = 'cust-live',
  String shopId = 'shop-live',
  String vehicleId = 'veh-live',
  DateTime? pickup,
}) {
  final now = pickup ?? DateTime.now().add(const Duration(days: 1));
  return ds.createBookingRequest(
    customerId: customerId,
    shopId: shopId,
    vehicleId: vehicleId,
    packageType: '24h',
    isWithDriver: false,
    pickupTime: now,
    returnTime: now.add(const Duration(days: 2)),
    totalAmount: 12000,
    advanceRequired: 3000,
    vehicleName: 'Toyota Corolla',
    vehiclePlate: 'LEA-24-100',
    shopName: 'Live Shop',
  );
}

/// Lets the async* fallback streams deliver their next emission.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 100));

void main() {
  group('booking data source live streams', () {
    test('streamCustomerBookings emits the new booking after submit',
        () async {
      final ds = BookingRemoteDataSource();
      final seen = <List<BookingEntity>>[];
      final sub = ds.streamCustomerBookings('cust-live').listen(seen.add);
      await _settle();
      expect(seen.length, 1);
      expect(seen.last, isEmpty);

      final booking = await _submit(ds);
      await _settle();
      expect(seen.length, 2);
      expect(seen.last.map((b) => b.bookingId), contains(booking.bookingId));
      expect(seen.last.single.status, 'requested');
      await sub.cancel();
    });

    test('streamCustomerBookings emits the owner status change', () async {
      final ds = BookingRemoteDataSource();
      final booking = await _submit(ds);
      final seen = <List<BookingEntity>>[];
      final sub = ds.streamCustomerBookings('cust-live').listen(seen.add);
      await _settle();
      expect(seen.last.single.status, 'requested');

      await ds.updateBookingStatus(
          bookingId: booking.bookingId, status: 'approved');
      await _settle();
      expect(seen.last.single.status, 'approved');
      await sub.cancel();
    });

    test('streamShopBookings emits the new booking for the shop',
        () async {
      final ds = BookingRemoteDataSource();
      final seen = <List<BookingEntity>>[];
      final sub = ds.streamShopBookings('shop-live').listen(seen.add);
      await _settle();
      expect(seen.last, isEmpty);

      final booking = await _submit(ds);
      await _settle();
      expect(seen.last.map((b) => b.bookingId), contains(booking.bookingId));
      await sub.cancel();
    });

    test('streamVehicleBookings emits the new booking for the vehicle',
        () async {
      final ds = BookingRemoteDataSource();
      final seen = <List<BookingEntity>>[];
      final sub = ds.streamVehicleBookings('veh-live').listen(seen.add);
      await _settle();
      expect(seen.last, isEmpty);

      final booking = await _submit(ds);
      await _settle();
      expect(seen.last.map((b) => b.bookingId), contains(booking.bookingId));
      await sub.cancel();
    });

    test('streamBooking emits the booking, then its status change',
        () async {
      final ds = BookingRemoteDataSource();
      final booking = await _submit(ds);
      final seen = <BookingEntity?>[];
      final sub = ds.streamBooking(booking.bookingId).listen(seen.add);
      await _settle();
      expect(seen.last?.status, 'requested');

      await ds.updateBookingStatus(
          bookingId: booking.bookingId, status: 'paid');
      await _settle();
      expect(seen.last?.status, 'paid');
      await sub.cancel();
    });

    test('a payment verify re-emits to customer and shop listeners',
        () async {
      final ds = BookingRemoteDataSource();
      final customerSeen = <List<BookingEntity>>[];
      final shopSeen = <List<BookingEntity>>[];
      final sub1 =
          ds.streamCustomerBookings('cust-live').listen(customerSeen.add);
      final sub2 = ds.streamShopBookings('shop-live').listen(shopSeen.add);
      final booking = await _submit(ds);
      await _settle();
      expect(customerSeen.last.single.status, 'requested');

      await ds.verifyPayment(
          bookingId: booking.bookingId, advanceAmount: 3000);
      await _settle();
      expect(customerSeen.last.single.status, 'paid');
      expect(customerSeen.last.single.advancePaid, 3000);
      expect(shopSeen.last.single.status, 'paid');
      await sub1.cancel();
      await sub2.cancel();
    });
  });

  group('customer home and wallet live streams', () {
    CustomerHomeService buildHomeService(BookingRemoteDataSource ds) {
      return CustomerHomeService(
        bookings: ds,
        wallet: CustomerWalletService(
          bookings: ds,
          deposits: SecurityDepositDataSource(),
        ),
        kyc: KycRemoteDataSource(
            storageClient: CPanelStorageClient(apiSecretKey: 'test')),
        users: FirestoreService(),
      );
    }

    test('home watch emits updated KPIs after a booking submit',
        () async {
      final ds = BookingRemoteDataSource();
      final service = buildHomeService(ds);
      final seen = <CustomerHomeData>[];
      final sub = service.watch('cust-live').listen(seen.add);
      await _settle();
      expect(seen.length, 1);
      expect(seen.last.activeBookings, 0);
      expect(seen.last.totalTrips, 0);

      final booking = await _submit(ds);
      await _settle();
      expect(seen.last.bookings.map((b) => b.bookingId),
          contains(booking.bookingId));
      expect(seen.last.recentBookings.length, 1);

      await ds.updateBookingStatus(
          bookingId: booking.bookingId, status: 'paid');
      await _settle();
      expect(seen.last.activeBookings, 1);
      await sub.cancel();
    });

    test('wallet watch emits the advance after payment verify',
        () async {
      final ds = BookingRemoteDataSource();
      final wallet = CustomerWalletService(
        bookings: ds,
        deposits: SecurityDepositDataSource(),
      );
      final seen = <CustomerWalletSummary>[];
      final sub = wallet.watch('cust-live').listen(seen.add);
      await _settle();
      expect(seen.last.total, 0);

      final booking = await _submit(ds);
      await _settle();
      // Requested, nothing paid yet — still zero.
      expect(seen.last.total, 0);

      await ds.verifyPayment(
          bookingId: booking.bookingId, advanceAmount: 3000);
      await _settle();
      expect(seen.last.advancesPaid, 3000);
      expect(seen.last.total, 3000);
      expect(seen.last.entries.length, 1);
      await sub.cancel();
    });
  });
}
