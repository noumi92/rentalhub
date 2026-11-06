import '../repositories/fleet_repository.dart';

/// Phase B (B1): flip a vehicle between 'available' and 'maintenance'
/// from the fleet list. The toggle never writes 'rented' — a vehicle
/// becomes rented only through a booking lifecycle change.
class UpdateVehicleStatusUseCase {
  final FleetRepository repository;

  const UpdateVehicleStatusUseCase(this.repository);

  Future<void> call({
    required String vehicleId,
    required String status,
  }) async {
    if (status != 'available' && status != 'maintenance') {
      throw ArgumentError(
        'Vehicle status must be available or maintenance, got: $status',
      );
    }
    return repository.updateVehicleStatus(
      vehicleId: vehicleId,
      status: status,
    );
  }
}
