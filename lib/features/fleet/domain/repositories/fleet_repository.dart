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
  /// Phase B (B2): writes the whole pricing set (rates, packages, weekly
  /// rate, deposit, advance, extra hour, driver surcharge, fuel policy
  /// and drive-mode availability) from one updated [VehicleEntity].
  Future<void> updateVehiclePricing({
    required String vehicleId,
    required VehicleEntity vehicle,
  });
}

