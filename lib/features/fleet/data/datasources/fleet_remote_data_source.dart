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
      final old = _inMemoryVehicles[idx];
      _inMemoryVehicles[idx] = VehicleModel(
        vehicleId: old.vehicleId,
        shopId: old.shopId,
        make: old.make,
        model: old.model,
        year: old.year,
        plateNumber: old.plateNumber,
        category: old.category,
        transmission: old.transmission,
        fuelType: old.fuelType,
        seats: old.seats,
        isSelfDriveAvailable: old.isSelfDriveAvailable,
        isWithDriverAvailable: old.isWithDriverAvailable,
        rates: ratesModel,
        status: old.status,
      );
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
      final old = _inMemoryVehicles[idx];
      _inMemoryVehicles[idx] = VehicleModel(
        vehicleId: old.vehicleId,
        shopId: old.shopId,
        make: old.make,
        model: old.model,
        year: old.year,
        plateNumber: old.plateNumber,
        category: old.category,
        transmission: old.transmission,
        fuelType: old.fuelType,
        seats: old.seats,
        isSelfDriveAvailable: old.isSelfDriveAvailable,
        isWithDriverAvailable: old.isWithDriverAvailable,
        rates: old.rates,
        status: status,
      );
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
}
