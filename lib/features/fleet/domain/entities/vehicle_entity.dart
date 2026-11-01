import 'package:equatable/equatable.dart';

class VehicleRatesEntity extends Equatable {
  final int? hourly1;
  final int? hourly3;
  final int? hourly6;
  final int daily24;
  final int? outOfCityDaily;

  const VehicleRatesEntity({
    this.hourly1,
    this.hourly3,
    this.hourly6,
    required this.daily24,
    this.outOfCityDaily,
  });

  @override
  List<Object?> get props => [
        hourly1,
        hourly3,
        hourly6,
        daily24,
        outOfCityDaily,
      ];
}

class VehicleEntity extends Equatable {
  final String vehicleId;
  final String shopId;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String category;
  final String transmission;
  final String fuelType;
  final int seats;
  final bool isSelfDriveAvailable;
  final bool isWithDriverAvailable;
  final VehicleRatesEntity rates;
  final String status; // 'available' | 'rented' | 'maintenance'

  const VehicleEntity({
    required this.vehicleId,
    required this.shopId,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    this.category = 'Sedan',
    this.transmission = 'Automatic',
    this.fuelType = 'Petrol',
    this.seats = 5,
    this.isSelfDriveAvailable = true,
    this.isWithDriverAvailable = true,
    required this.rates,
    this.status = 'available',
  });

  @override
  List<Object?> get props => [
        vehicleId,
        shopId,
        make,
        model,
        year,
        plateNumber,
        category,
        transmission,
        fuelType,
        seats,
        isSelfDriveAvailable,
        isWithDriverAvailable,
        rates,
        status,
      ];
}

