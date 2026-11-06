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

  // Phase B (B1): vehicle identity + pricing fields the Gaari spec needs.
  // All optional — older vehicle documents without them still read fine.
  final String? imageUrl;
  final String? color;
  final int? mileageKm;
  final String? chassisNumber;
  final String? engineNumber;
  final int? engineCc;
  final List<String> features;
  final String? trackerProvider;
  final String? insurancePolicy;
  final int? weeklyRate;
  final int? securityDepositPkr;
  final int? advanceRequiredPkr;
  final int? extraHourPkr;
  final int? withDriverSurchargePkr;
  final String? fuelPolicy;

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
    this.imageUrl,
    this.color,
    this.mileageKm,
    this.chassisNumber,
    this.engineNumber,
    this.engineCc,
    this.features = const [],
    this.trackerProvider,
    this.insurancePolicy,
    this.weeklyRate,
    this.securityDepositPkr,
    this.advanceRequiredPkr,
    this.extraHourPkr,
    this.withDriverSurchargePkr,
    this.fuelPolicy,
  });

  /// Display name used across owner and customer screens.
  String get displayName => '$make $model $year';

  VehicleEntity copyWith({
    String? vehicleId,
    String? shopId,
    String? make,
    String? model,
    int? year,
    String? plateNumber,
    String? category,
    String? transmission,
    String? fuelType,
    int? seats,
    bool? isSelfDriveAvailable,
    bool? isWithDriverAvailable,
    VehicleRatesEntity? rates,
    String? status,
    String? imageUrl,
    String? color,
    int? mileageKm,
    String? chassisNumber,
    String? engineNumber,
    int? engineCc,
    List<String>? features,
    String? trackerProvider,
    String? insurancePolicy,
    int? weeklyRate,
    int? securityDepositPkr,
    int? advanceRequiredPkr,
    int? extraHourPkr,
    int? withDriverSurchargePkr,
    String? fuelPolicy,
  }) {
    return VehicleEntity(
      vehicleId: vehicleId ?? this.vehicleId,
      shopId: shopId ?? this.shopId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      category: category ?? this.category,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      seats: seats ?? this.seats,
      isSelfDriveAvailable: isSelfDriveAvailable ?? this.isSelfDriveAvailable,
      isWithDriverAvailable:
          isWithDriverAvailable ?? this.isWithDriverAvailable,
      rates: rates ?? this.rates,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      mileageKm: mileageKm ?? this.mileageKm,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      engineCc: engineCc ?? this.engineCc,
      features: features ?? this.features,
      trackerProvider: trackerProvider ?? this.trackerProvider,
      insurancePolicy: insurancePolicy ?? this.insurancePolicy,
      weeklyRate: weeklyRate ?? this.weeklyRate,
      securityDepositPkr: securityDepositPkr ?? this.securityDepositPkr,
      advanceRequiredPkr: advanceRequiredPkr ?? this.advanceRequiredPkr,
      extraHourPkr: extraHourPkr ?? this.extraHourPkr,
      withDriverSurchargePkr:
          withDriverSurchargePkr ?? this.withDriverSurchargePkr,
      fuelPolicy: fuelPolicy ?? this.fuelPolicy,
    );
  }

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
        imageUrl,
        color,
        mileageKm,
        chassisNumber,
        engineNumber,
        engineCc,
        features,
        trackerProvider,
        insurancePolicy,
        weeklyRate,
        securityDepositPkr,
        advanceRequiredPkr,
        extraHourPkr,
        withDriverSurchargePkr,
        fuelPolicy,
      ];
}

