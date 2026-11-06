import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/fleet_remote_data_source.dart';

class FleetRepositoryImpl implements FleetRepository {
  final FleetRemoteDataSource remoteDataSource;
  const FleetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<int> getActiveVehicleCount(String shopId) =>
      remoteDataSource.getActiveVehicleCount(shopId);

  @override
  Future<String> getShopSubscriptionTier(String shopId) =>
      remoteDataSource.getShopSubscriptionTier(shopId);

  @override
  Future<List<VehicleEntity>> getShopVehicles(String shopId) =>
      remoteDataSource.getShopVehicles(shopId);

  @override
  Future<void> addVehicle({
    required String shopId,
    required VehicleEntity vehicle,
  }) =>
      remoteDataSource.addVehicle(shopId: shopId, vehicle: vehicle);

  @override
  Future<void> updateVehicleStatus({
    required String vehicleId,
    required String status,
  }) =>
      remoteDataSource.updateVehicleStatus(
        vehicleId: vehicleId,
        status: status,
      );

  @override
  Future<void> updateVehiclePricing({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) =>
      remoteDataSource.updateVehiclePricing(
        vehicleId: vehicleId,
        vehicle: vehicle,
      );
}

