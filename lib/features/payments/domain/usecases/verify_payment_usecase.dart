import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/domain/repositories/booking_repository.dart';

class VerifyPaymentUseCase {
  final BookingRepository bookingRepository;
  const VerifyPaymentUseCase(this.bookingRepository);

  Future<BookingEntity> call({
    required String bookingId,
    required int advanceAmount,
  }) =>
      bookingRepository.verifyPayment(
        bookingId: bookingId,
        advanceAmount: advanceAmount,
      );
}
