import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../models/vehicle_model.dart';

class FleetRemoteDataSource {
  final FirebaseFirestore? _firestore;

  final Map<String, String> _shopTiers = {
    'shop-basic': 'basic',
    'shop-1': 'pro',
  };

  final List<VehicleModel> _inMemoryVehicles = [
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

  FleetRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<int> getActiveVehicleCount(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('vehicles')
            .where('shopId', isEqualTo: shopId)
            .get();
        if (snap.docs.isNotEmpty) return snap.docs.length;
      } catch (_) {}
    }
    return _inMemoryVehicles.where((v) => v.shopId == shopId).length;
  }

  Future<String> getShopSubscriptionTier(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final doc = await fs.collection('shops').doc(shopId).get();
        if (doc.exists && doc.data() != null) {
          return (doc.data()!['subscriptionTier'] as String?) ?? 'basic';
        }
      } catch (_) {}
    }
    return _shopTiers[shopId] ?? 'basic';
  }

  Future<List<VehicleEntity>> getShopVehicles(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('vehicles')
            .where('shopId', isEqualTo: shopId)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => VehicleModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _inMemoryVehicles.where((v) => v.shopId == shopId).toList();
  }

  Future<void> addVehicle({
    required String shopId,
    required VehicleEntity vehicle,
  }) async {
    final model = VehicleModel.fromEntity(vehicle);
    _inMemoryVehicles.add(model);

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs
            .collection('vehicles')
            .doc(vehicle.vehicleId)
            .set(model.toMap());
      } catch (_) {}
    }
  }

  Future<void> updateVehicleRates({
    required String vehicleId,
    required VehicleRatesEntity rates,
  }) async {
    final ratesModel = VehicleRatesModel.fromEntity(rates);
    final idx = _inMemoryVehicles.indexWhere((v) => v.vehicleId == vehicleId);
    if (idx != -1) {
      _inMemoryVehicles[idx] =
          _inMemoryVehicles[idx].copyWith(rates: ratesModel);
    }

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('vehicles').doc(vehicleId).update({
          'rates': ratesModel.toMap(),
        });
      } catch (_) {}
    }
  }

  Future<void> updateVehicleStatus({
    required String vehicleId,
    required String status,
  }) async {
    final idx = _inMemoryVehicles.indexWhere((v) => v.vehicleId == vehicleId);
    if (idx != -1) {
      _inMemoryVehicles[idx] =
          _inMemoryVehicles[idx].copyWith(status: status);
    }

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('vehicles').doc(vehicleId).update({
          'status': status,
        });
      } catch (_) {}
    }
  }

  /// Phase B (F1): the odometer advances by the trip at return, so
  /// the fleet's mileage stays true instead of freezing at the
  /// value recorded when the car was added.
  Future<void> updateVehicleMileage({
    required String vehicleId,
    required int mileageKm,
  }) async {
    final idx = _inMemoryVehicles.indexWhere((v) => v.vehicleId == vehicleId);
    if (idx != -1) {
      _inMemoryVehicles[idx] =
          _inMemoryVehicles[idx].copyWith(mileageKm: mileageKm);
    }

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('vehicles').doc(vehicleId).update({
          'mileageKm': mileageKm,
        });
      } catch (_) {}
    }
  }

  /// Phase B (B2): writes the whole pricing set. The in-memory list gets
  /// the full updated entity; Firestore gets the same fields (the
  /// pricing subset of `toMap`, so the document keeps its identity
  /// fields untouched).
  Future<void> updateVehiclePricing({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) async {
    final model = VehicleModel.fromEntity(vehicle);
    final idx = _inMemoryVehicles.indexWhere((v) => v.vehicleId == vehicleId);
    if (idx != -1) {
      _inMemoryVehicles[idx] = model;
    }

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final map = model.toMap();
        // Firestore deletes a field on a null update value, so only
        // send the fields that are actually set.
        final update = <String, dynamic>{
          'rates': map['rates'],
          'packages': map['packages'] ?? [],
          'isSelfDriveAvailable': model.isSelfDriveAvailable,
          'isWithDriverAvailable': model.isWithDriverAvailable,
          if (map['weeklyRate'] != null) 'weeklyRate': map['weeklyRate'],
          if (map['securityDepositPkr'] != null)
            'securityDepositPkr': map['securityDepositPkr'],
          if (map['advanceRequiredPkr'] != null)
            'advanceRequiredPkr': map['advanceRequiredPkr'],
          if (map['extraHourPkr'] != null)
            'extraHourPkr': map['extraHourPkr'],
          if (map['withDriverSurchargePkr'] != null)
            'withDriverSurchargePkr': map['withDriverSurchargePkr'],
          if (map['fuelPolicy'] != null) 'fuelPolicy': map['fuelPolicy'],
          if (map['extraKmPkr'] != null) 'extraKmPkr': map['extraKmPkr'],
          if (map['outOfCityKmPerDay'] != null)
            'outOfCityKmPerDay': map['outOfCityKmPerDay'],
        };
        await fs.collection('vehicles').doc(vehicleId).update(update);
      } catch (_) {}
    }
  }
}
