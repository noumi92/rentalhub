import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class CreateBookingRequestUseCase {
  final BookingRepository repository;
  const CreateBookingRequestUseCase(this.repository);

  Future<BookingEntity> call({
    required String customerId,
    required String shopId,
    required String vehicleId,
    required String packageType,
    required bool isWithDriver,
    required DateTime pickupTime,
    required DateTime returnTime,
    required int totalAmount,
    required int advanceRequired,
  }) =>
      repository.createBookingRequest(
        customerId: customerId,
        shopId: shopId,
        vehicleId: vehicleId,
        packageType: packageType,
        isWithDriver: isWithDriver,
        pickupTime: pickupTime,
        returnTime: returnTime,
        totalAmount: totalAmount,
        advanceRequired: advanceRequired,
      );
}

