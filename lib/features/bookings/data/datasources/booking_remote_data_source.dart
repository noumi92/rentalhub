import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

class BookingRemoteDataSource {
  final Map<String, BookingModel> _bookings = {};

  Future<BookingModel> createBookingRequest({
    required String customerId,
    required String shopId,
    required String vehicleId,
    required String packageType,
    required bool isWithDriver,
    required DateTime pickupTime,
    required DateTime returnTime,
    required int totalAmount,
    required int advanceRequired,
  }) async {
    final id = 'RH-${84920 + _bookings.length}';
    final model = BookingModel(
      bookingId: id,
      customerId: customerId,
      shopId: shopId,
      vehicleId: vehicleId,
      packageType: packageType,
      isWithDriver: isWithDriver,
      pickupTime: pickupTime,
      returnTime: returnTime,
      totalAmount: totalAmount,
      advanceRequired: advanceRequired,
      advancePaid: 0,
      remainingBalance: totalAmount,
      status: 'requested',
    );
    _bookings[id] = model;
    return model;
  }

  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final existing = _bookings[bookingId];
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final updated = existing.copyWith(status: status);
    _bookings[bookingId] = BookingModel(
      bookingId: updated.bookingId,
      customerId: updated.customerId,
      shopId: updated.shopId,
      vehicleId: updated.vehicleId,
      packageType: updated.packageType,
      isWithDriver: updated.isWithDriver,
      pickupTime: updated.pickupTime,
      returnTime: updated.returnTime,
      totalAmount: updated.totalAmount,
      advanceRequired: updated.advanceRequired,
      advancePaid: updated.advancePaid,
      remainingBalance: updated.remainingBalance,
      status: updated.status,
      paymentProofUrl: updated.paymentProofUrl,
      transactionId: updated.transactionId,
    );
    return _bookings[bookingId]!;
  }

  Future<BookingEntity> updatePaymentProof({
    required String bookingId,
    required String paymentProofUrl,
    required String transactionId,
  }) async {
    final existing = _bookings[bookingId];
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final updated = existing.copyWith(
      status: 'payment_submitted',
      paymentProofUrl: paymentProofUrl,
      transactionId: transactionId,
    );
    _bookings[bookingId] = BookingModel(
      bookingId: updated.bookingId,
      customerId: updated.customerId,
      shopId: updated.shopId,
      vehicleId: updated.vehicleId,
      packageType: updated.packageType,
      isWithDriver: updated.isWithDriver,
      pickupTime: updated.pickupTime,
      returnTime: updated.returnTime,
      totalAmount: updated.totalAmount,
      advanceRequired: updated.advanceRequired,
      advancePaid: updated.advancePaid,
      remainingBalance: updated.remainingBalance,
      status: updated.status,
      paymentProofUrl: updated.paymentProofUrl,
      transactionId: updated.transactionId,
    );
    return _bookings[bookingId]!;
  }

  Future<BookingEntity> verifyPayment({
    required String bookingId,
    required int advanceAmount,
  }) async {
    final existing = _bookings[bookingId];
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final updated = existing.copyWith(
      status: 'paid',
      advancePaid: advanceAmount,
    );
    _bookings[bookingId] = BookingModel(
      bookingId: updated.bookingId,
      customerId: updated.customerId,
      shopId: updated.shopId,
      vehicleId: updated.vehicleId,
      packageType: updated.packageType,
      isWithDriver: updated.isWithDriver,
      pickupTime: updated.pickupTime,
      returnTime: updated.returnTime,
      totalAmount: updated.totalAmount,
      advanceRequired: updated.advanceRequired,
      advancePaid: updated.advancePaid,
      remainingBalance: updated.remainingBalance,
      status: updated.status,
      paymentProofUrl: updated.paymentProofUrl,
      transactionId: updated.transactionId,
    );
    return _bookings[bookingId]!;
  }

  Future<List<BookingEntity>> getCustomerBookings(String customerId) async {
    return _bookings.values
        .where((b) => b.customerId == customerId)
        .toList();
  }
}

