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
    super.imageUrl,
    super.color,
    super.mileageKm,
    super.chassisNumber,
    super.engineNumber,
    super.engineCc,
    super.features,
    super.trackerProvider,
    super.insurancePolicy,
    super.weeklyRate,
    super.securityDepositPkr,
    super.advanceRequiredPkr,
    super.extraHourPkr,
    super.withDriverSurchargePkr,
    super.fuelPolicy,
  });

  @override
  VehicleModel copyWith({
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
    return VehicleModel(
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
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (color != null) 'color': color,
      if (mileageKm != null) 'mileageKm': mileageKm,
      if (chassisNumber != null) 'chassisNumber': chassisNumber,
      if (engineNumber != null) 'engineNumber': engineNumber,
      if (engineCc != null) 'engineCc': engineCc,
      if (features.isNotEmpty) 'features': features,
      if (trackerProvider != null) 'trackerProvider': trackerProvider,
      if (insurancePolicy != null) 'insurancePolicy': insurancePolicy,
      if (weeklyRate != null) 'weeklyRate': weeklyRate,
      if (securityDepositPkr != null)
        'securityDepositPkr': securityDepositPkr,
      if (advanceRequiredPkr != null)
        'advanceRequiredPkr': advanceRequiredPkr,
      if (extraHourPkr != null) 'extraHourPkr': extraHourPkr,
      if (withDriverSurchargePkr != null)
        'withDriverSurchargePkr': withDriverSurchargePkr,
      if (fuelPolicy != null) 'fuelPolicy': fuelPolicy,
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
      imageUrl: map['imageUrl'] as String?,
      color: map['color'] as String?,
      mileageKm: (map['mileageKm'] as num?)?.toInt(),
      chassisNumber: map['chassisNumber'] as String?,
      engineNumber: map['engineNumber'] as String?,
      engineCc: (map['engineCc'] as num?)?.toInt(),
      features: (map['features'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      trackerProvider: map['trackerProvider'] as String?,
      insurancePolicy: map['insurancePolicy'] as String?,
      weeklyRate: (map['weeklyRate'] as num?)?.toInt(),
      securityDepositPkr: (map['securityDepositPkr'] as num?)?.toInt(),
      advanceRequiredPkr: (map['advanceRequiredPkr'] as num?)?.toInt(),
      extraHourPkr: (map['extraHourPkr'] as num?)?.toInt(),
      withDriverSurchargePkr:
          (map['withDriverSurchargePkr'] as num?)?.toInt(),
      fuelPolicy: map['fuelPolicy'] as String?,
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
      imageUrl: entity.imageUrl,
      color: entity.color,
      mileageKm: entity.mileageKm,
      chassisNumber: entity.chassisNumber,
      engineNumber: entity.engineNumber,
      engineCc: entity.engineCc,
      features: entity.features,
      trackerProvider: entity.trackerProvider,
      insurancePolicy: entity.insurancePolicy,
      weeklyRate: entity.weeklyRate,
      securityDepositPkr: entity.securityDepositPkr,
      advanceRequiredPkr: entity.advanceRequiredPkr,
      extraHourPkr: entity.extraHourPkr,
      withDriverSurchargePkr: entity.withDriverSurchargePkr,
      fuelPolicy: entity.fuelPolicy,
    );
  }
}
