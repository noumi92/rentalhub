import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class UpdateBookingStatusUseCase {
  final BookingRepository repository;
  const UpdateBookingStatusUseCase(this.repository);

  Future<BookingEntity> call({
    required String bookingId,
    required String status,
    String? selectedPaymentAccount,
    DateTime? paymentDeadline,
  }) =>
      repository.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        selectedPaymentAccount: selectedPaymentAccount,
        paymentDeadline: paymentDeadline,
      );
}

