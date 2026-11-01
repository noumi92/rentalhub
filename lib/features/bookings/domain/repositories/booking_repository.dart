import '../entities/booking_entity.dart';

abstract class BookingRepository {
  Future<BookingEntity> createBookingRequest({
    required String customerId,
    required String shopId,
    required String vehicleId,
    required String packageType,
    required bool isWithDriver,
    required DateTime pickupTime,
    required DateTime returnTime,
    required int totalAmount,
    required int advanceRequired,
  });

  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
  });

  Future<BookingEntity> updatePaymentProof({
    required String bookingId,
    required String paymentProofUrl,
    required String transactionId,
  });

  Future<BookingEntity> verifyPayment({
    required String bookingId,
    required int advanceAmount,
  });

  Future<List<BookingEntity>> getCustomerBookings(String customerId);
}

