import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.bookingId,
    required super.customerId,
    required super.shopId,
    required super.vehicleId,
    required super.packageType,
    super.isWithDriver,
    required super.pickupTime,
    required super.returnTime,
    required super.totalAmount,
    super.advanceRequired,
    super.advancePaid,
    required super.remainingBalance,
    super.status,
    super.paymentProofUrl,
    super.transactionId,
  });
}

