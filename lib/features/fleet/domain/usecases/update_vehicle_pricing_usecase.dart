import '../entities/vehicle_entity.dart';
import '../repositories/fleet_repository.dart';

/// Phase B (B2): saves the rate matrix — packages with their on/off
/// toggles, the legacy rate mirror, and the pricing policy fields
/// (deposit, advance, extra hour, driver surcharge, fuel policy,
/// drive-mode availability) in one write.
class UpdateVehiclePricingUseCase {
  final FleetRepository repository;

  const UpdateVehiclePricingUseCase(this.repository);

  Future<void> call({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) {
    if (vehicle.vehicleId != vehicleId) {
      throw ArgumentError(
        'Pricing update vehicleId mismatch: ${vehicle.vehicleId} != $vehicleId',
      );
    }
    return repository.updateVehiclePricing(
      vehicleId: vehicleId,
      vehicle: vehicle,
    );
  }
}
