import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class GetCustomerBookingsUseCase {
  final BookingRepository repository;
  const GetCustomerBookingsUseCase(this.repository);

  Future<List<BookingEntity>> call(String customerId) =>
      repository.getCustomerBookings(customerId);
}

