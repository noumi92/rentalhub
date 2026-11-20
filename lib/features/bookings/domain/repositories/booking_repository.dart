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
    String? fixedRouteId,
    String? fixedRouteSummary,
    String? outCityMode,
    int? outCityPerKmPkr,
  });

  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
    String? selectedPaymentAccount,
    DateTime? paymentDeadline,
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

  /// Live updates (Item 2): the same reads as [getCustomerBookings]
  /// and the shop/vehicle lists, as Firestore snapshot streams (or
  /// the live in-memory fallback when offline) — a booking submitted
  /// or re-statused anywhere reaches subscribers without a reload.
  Stream<List<BookingEntity>> streamCustomerBookings(String customerId);
  Stream<List<BookingEntity>> streamShopBookings(String shopId);
  Stream<List<BookingEntity>> streamVehicleBookings(String vehicleId);
  Stream<BookingEntity?> streamBooking(String bookingId);
}

