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

/// Phase B (B2): one rentable package of a vehicle. The owner sets the
/// price and on/off toggle per package in the rate matrix; the booking
/// picker only offers enabled packages and totals from these prices —
/// never from a formula.
class VehiclePackageEntity extends Equatable {
  /// '1h' | '3h' | '6h' | '12h' | '24h' | 'Weekly'
  final String label;
  final int hours;
  final int pricePkr;
  final bool enabled;
  final int kmIncluded;

  const VehiclePackageEntity({
    required this.label,
    required this.hours,
    required this.pricePkr,
    this.enabled = true,
    required this.kmIncluded,
  });

  VehiclePackageEntity copyWith({
    String? label,
    int? hours,
    int? pricePkr,
    bool? enabled,
    int? kmIncluded,
  }) {
    return VehiclePackageEntity(
      label: label ?? this.label,
      hours: hours ?? this.hours,
      pricePkr: pricePkr ?? this.pricePkr,
      enabled: enabled ?? this.enabled,
      kmIncluded: kmIncluded ?? this.kmIncluded,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'hours': hours,
        'pricePkr': pricePkr,
        'enabled': enabled,
        'kmIncluded': kmIncluded,
      };

  factory VehiclePackageEntity.fromMap(Map<String, dynamic> map) =>
      VehiclePackageEntity(
        label: (map['label'] as String?) ?? '24h',
        hours: (map['hours'] as num?)?.toInt() ?? 24,
        pricePkr: (map['pricePkr'] as num?)?.toInt() ?? 0,
        enabled: (map['enabled'] as bool?) ?? true,
        kmIncluded: (map['kmIncluded'] as num?)?.toInt() ?? 250,
      );

  @override
  List<Object?> get props => [label, hours, pricePkr, enabled, kmIncluded];
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
  // Audit §5 (integration): the other six picked files' URLs.
  // uploadAllVehicleFiles uploads them, but without fields they
  // were uploaded yet unlinked. All optional — older documents
  // without them still read fine.
  final String? photoBackUrl;
  final String? photoSideUrl;
  final String? photoInteriorUrl;
  final String? regBookUrl;
  final String? tokenTaxUrl;
  final String? insuranceUrl;
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

  /// Phase B (B3): extra-km charge (Rs per km beyond the package's
  /// included km) and the out-of-city km allowance per day (default 350).
  final int? extraKmPkr;
  final int? outOfCityKmPerDay;

  /// Phase B (B2): the vehicle's rentable packages. Empty means "never
  /// set" — readers must use [effectivePackages], which derives the six
  /// standard packages from the legacy [rates] for older documents.
  final List<VehiclePackageEntity> packages;

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
    this.photoBackUrl,
    this.photoSideUrl,
    this.photoInteriorUrl,
    this.regBookUrl,
    this.tokenTaxUrl,
    this.insuranceUrl,
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
    this.packages = const [],
    this.extraKmPkr,
    this.outOfCityKmPerDay,
  });

  /// Display name used across owner and customer screens.
  String get displayName => '$make $model $year';

  /// The packages the booking picker offers: the stored list when the
  /// owner has set one, otherwise the six standard packages derived from
  /// the legacy rates (12h defaults to 60% of the daily rate, Weekly to
  /// the stored weekly rate or six days).
  List<VehiclePackageEntity> get effectivePackages {
    if (packages.isNotEmpty) return packages;
    final daily = rates.daily24;
    return [
      VehiclePackageEntity(
          label: '1h',
          hours: 1,
          pricePkr: rates.hourly1 ?? (daily * 0.15).round(),
          kmIncluded: 15),
      VehiclePackageEntity(
          label: '3h',
          hours: 3,
          pricePkr: rates.hourly3 ?? (daily * 0.35).round(),
          kmIncluded: 40),
      VehiclePackageEntity(
          label: '6h',
          hours: 6,
          pricePkr: rates.hourly6 ?? (daily * 0.6).round(),
          kmIncluded: 80),
      VehiclePackageEntity(
          label: '12h',
          hours: 12,
          pricePkr: (daily * 0.6).round(),
          kmIncluded: 150),
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: daily, kmIncluded: 250),
      VehiclePackageEntity(
          label: 'Weekly',
          hours: 168,
          pricePkr: weeklyRate ?? daily * 6,
          kmIncluded: 1750),
    ];
  }

  /// Packages the picker shows, in display order.
  List<VehiclePackageEntity> get enabledPackages =>
      effectivePackages.where((p) => p.enabled).toList();

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
    String? photoBackUrl,
    String? photoSideUrl,
    String? photoInteriorUrl,
    String? regBookUrl,
    String? tokenTaxUrl,
    String? insuranceUrl,
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
    List<VehiclePackageEntity>? packages,
    int? extraKmPkr,
    int? outOfCityKmPerDay,
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
      photoBackUrl: photoBackUrl ?? this.photoBackUrl,
      photoSideUrl: photoSideUrl ?? this.photoSideUrl,
      photoInteriorUrl: photoInteriorUrl ?? this.photoInteriorUrl,
      regBookUrl: regBookUrl ?? this.regBookUrl,
      tokenTaxUrl: tokenTaxUrl ?? this.tokenTaxUrl,
      insuranceUrl: insuranceUrl ?? this.insuranceUrl,
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
      packages: packages ?? this.packages,
      extraKmPkr: extraKmPkr ?? this.extraKmPkr,
      outOfCityKmPerDay: outOfCityKmPerDay ?? this.outOfCityKmPerDay,
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
        photoBackUrl,
        photoSideUrl,
        photoInteriorUrl,
        regBookUrl,
        tokenTaxUrl,
        insuranceUrl,
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
        packages,
        extraKmPkr,
        outOfCityKmPerDay,
      ];
}

