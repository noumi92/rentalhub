import '../../domain/entities/vehicle_entity.dart';
import '../models/vehicle_model.dart';

class FleetRemoteDataSource {
  final Map<String, String> _shopTiers = {
    'shop-basic': 'basic',
    'shop-1': 'pro',
  };

  final List<VehicleModel> _vehicles = [
    const VehicleModel(
      vehicleId: 'v1',
      shopId: 'shop-basic',
      make: 'Honda',
      model: 'Civic Oriel',
      year: 2021,
      plateNumber: 'LEA-4820',
      rates: VehicleRatesModel(
        hourly1: 1500,
        hourly3: 3500,
        hourly6: 6000,
        daily24: 9000,
        outOfCityDaily: 11500,
      ),
    ),
    const VehicleModel(
      vehicleId: 'v2',
      shopId: 'shop-basic',
      make: 'Toyota',
      model: 'Corolla Grande',
      year: 2022,
      plateNumber: 'ICT-9912',
      rates: VehicleRatesModel(
        hourly1: 1400,
        hourly3: 3200,
        hourly6: 5500,
        daily24: 8500,
        outOfCityDaily: 10500,
      ),
    ),
    const VehicleModel(
      vehicleId: 'v3',
      shopId: 'shop-basic',
      make: 'Suzuki',
      model: 'Alto VXL',
      year: 2023,
      plateNumber: 'LHR-1029',
      rates: VehicleRatesModel(
        hourly1: 800,
        hourly3: 1800,
        hourly6: 2800,
        daily24: 3500,
        outOfCityDaily: 4800,
      ),
    ),
  ];

  Future<int> getActiveVehicleCount(String shopId) async {
    return _vehicles.where((v) => v.shopId == shopId).length;
  }

  Future<String> getShopSubscriptionTier(String shopId) async {
    return _shopTiers[shopId] ?? 'basic';
  }

  Future<List<VehicleEntity>> getShopVehicles(String shopId) async {
    return _vehicles.where((v) => v.shopId == shopId).toList();
  }

  Future<void> addVehicle({
    required String shopId,
    required VehicleEntity vehicle,
  }) async {
    _vehicles.add(
      VehicleModel(
        vehicleId: vehicle.vehicleId,
        shopId: shopId,
        make: vehicle.make,
        model: vehicle.model,
        year: vehicle.year,
        plateNumber: vehicle.plateNumber,
        category: vehicle.category,
        transmission: vehicle.transmission,
        fuelType: vehicle.fuelType,
        seats: vehicle.seats,
        isSelfDriveAvailable: vehicle.isSelfDriveAvailable,
        isWithDriverAvailable: vehicle.isWithDriverAvailable,
        rates: vehicle.rates,
        status: vehicle.status,
      ),
    );
  }
}

