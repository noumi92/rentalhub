import '../entities/vehicle_entity.dart';
import '../repositories/fleet_repository.dart';

/// Saves the car-details edit — the vehicle's identity fields
/// (make, model, year, plate, category, transmission, fuel, seats,
/// color, features, front photo, status) in one write. Rates,
/// packages and pricing policy fields are NOT touched here; they
/// live on [UpdateVehiclePricingUseCase].
class UpdateVehicleUseCase {
  final FleetRepository repository;

  const UpdateVehicleUseCase(this.repository);

  Future<void> call({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) {
    if (vehicle.vehicleId != vehicleId) {
      throw ArgumentError(
        'Details update vehicleId mismatch: ${vehicle.vehicleId} != $vehicleId',
      );
    }
    return repository.updateVehicleDetails(
      vehicleId: vehicleId,
      vehicle: vehicle,
    );
  }
}
