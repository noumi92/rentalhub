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
        hourly1: (map['hourly_1'] as num?)?.toInt(),
        hourly3: (map['hourly_3'] as num?)?.toInt(),
        hourly6: (map['hourly_6'] as num?)?.toInt(),
        daily24: (map['daily_24'] as num?)?.toInt() ?? 0,
        outOfCityDaily: (map['out_of_city'] as num?)?.toInt(),
      );

  factory VehicleRatesModel.fromEntity(VehicleRatesEntity entity) =>
      VehicleRatesModel(
        hourly1: entity.hourly1,
        hourly3: entity.hourly3,
        hourly6: entity.hourly6,
        daily24: entity.daily24,
        outOfCityDaily: entity.outOfCityDaily,
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

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'shopId': shopId,
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'category': category,
      'transmission': transmission,
      'fuelType': fuelType,
      'seats': seats,
      'isSelfDriveAvailable': isSelfDriveAvailable,
      'isWithDriverAvailable': isWithDriverAvailable,
      'rates': VehicleRatesModel.fromEntity(rates).toMap(),
      'status': status,
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return VehicleModel(
      vehicleId: id ?? (map['vehicleId'] as String? ?? ''),
      shopId: (map['shopId'] as String?) ?? '',
      make: (map['make'] as String?) ?? '',
      model: (map['model'] as String?) ?? '',
      year: (map['year'] as num?)?.toInt() ?? 2023,
      plateNumber: (map['plateNumber'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Sedan',
      transmission: (map['transmission'] as String?) ?? 'Automatic',
      fuelType: (map['fuelType'] as String?) ?? 'Petrol',
      seats: (map['seats'] as num?)?.toInt() ?? 5,
      isSelfDriveAvailable: (map['isSelfDriveAvailable'] as bool?) ?? true,
      isWithDriverAvailable: (map['isWithDriverAvailable'] as bool?) ?? true,
      rates: map['rates'] != null
          ? VehicleRatesModel.fromMap(
              Map<String, dynamic>.from(map['rates'] as Map))
          : const VehicleRatesModel(daily24: 5000),
      status: (map['status'] as String?) ?? 'available',
    );
  }

  factory VehicleModel.fromEntity(VehicleEntity entity) {
    return VehicleModel(
      vehicleId: entity.vehicleId,
      shopId: entity.shopId,
      make: entity.make,
      model: entity.model,
      year: entity.year,
      plateNumber: entity.plateNumber,
      category: entity.category,
      transmission: entity.transmission,
      fuelType: entity.fuelType,
      seats: entity.seats,
      isSelfDriveAvailable: entity.isSelfDriveAvailable,
      isWithDriverAvailable: entity.isWithDriverAvailable,
      rates: entity.rates,
      status: entity.status,
    );
  }
}
