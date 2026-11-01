import '../entities/vehicle_entity.dart';
import '../repositories/fleet_repository.dart';

class GetShopVehiclesUseCase {
  final FleetRepository repository;
  const GetShopVehiclesUseCase(this.repository);

  Future<List<VehicleEntity>> call(String shopId) =>
      repository.getShopVehicles(shopId);
}

