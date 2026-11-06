import '../entities/vehicle_entity.dart';

abstract class FleetRepository {
  Future<int> getActiveVehicleCount(String shopId);
  Future<String> getShopSubscriptionTier(String shopId);
  Future<List<VehicleEntity>> getShopVehicles(String shopId);
  Future<void> addVehicle({
    required String shopId,
    required VehicleEntity vehicle,
  });
  Future<void> updateVehicleStatus({
    required String vehicleId,
    required String status,
  });
}

