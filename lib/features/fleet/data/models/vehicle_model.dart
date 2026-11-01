import '../../domain/entities/vehicle_entity.dart';

class VehicleRatesModel extends VehicleRatesEntity {
  const VehicleRatesModel({
    super.hourly1,
    super.hourly3,
    super.hourly6,
    required super.daily24,
    super.outOfCityDaily,
  });

  Map<String, dynamic> toMap() => {
        'hourly_1': hourly1,
        'hourly_3': hourly3,
        'hourly_6': hourly6,
        'daily_24': daily24,
        'out_of_city': outOfCityDaily,
      };

  factory VehicleRatesModel.fromMap(Map<String, dynamic> map) =>
      VehicleRatesModel(
        hourly1: map['hourly_1'],
        hourly3: map['hourly_3'],
        hourly6: map['hourly_6'],
        daily24: map['daily_24'] ?? 0,
        outOfCityDaily: map['out_of_city'],
      );
}

class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.vehicleId,
    required super.shopId,
    required super.make,
    required super.model,
    required super.year,
    required super.plateNumber,
    super.category,
    super.transmission,
    super.fuelType,
    super.seats,
    super.isSelfDriveAvailable,
    super.isWithDriverAvailable,
    required super.rates,
    super.status,
  });
}

