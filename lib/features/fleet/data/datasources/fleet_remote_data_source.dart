import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../models/vehicle_model.dart';

class FleetRemoteDataSource {
  final FirebaseFirestore? _firestore;

  /// Phase B (B1/B3): the persisted pending-write store. When set,
  /// a failed Firestore write is queued instead of dying in memory.
  final OfflineSyncQueue? syncQueue;

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

  FleetRemoteDataSource({FirebaseFirestore? firestore, this.syncQueue})
      : _firestore = firestore;

  /// Phase B (B1/B4): one write path for vehicle docs — merge-set +
  /// server timestamp; on failure the write is queued (persisted)
  /// instead of dying in memory. Returns true when the server
  /// confirmed the write.
  Future<bool> _writeVehicleDoc(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      await fs.collection('vehicles').doc(vehicleId).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _queueVehicleWrite(
    String vehicleId,
    Map<String, dynamic> fields,
  ) async {
    final queue = syncQueue;
    if (queue == null) return;
    await queue.enqueue(
      kind: 'firestore_set',
      entityId: vehicleId,
      payload: {
        'collection': 'vehicles',
        'docId': vehicleId,
        'fields': fields,
      },
    );
  }

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Shop-id resolution caches. The owner app and the customer app
  /// disagree about what a shop's id is (see below); the lookups are
  /// small but they run on every fleet load, so the mapping is cached
  /// for the life of this data source (a lazy singleton).
  final Map<String, List<String>> _candidateShopIdsCache = {};
  final Map<String, String> _canonicalShopIdCache = {};

  /// Shop-id mismatch (2026-11-11): the owner app writes vehicles with
  /// `shopId` = the signed-in owner's UID (`currentShopId()`), while the
  /// customer app reads vehicles by shop DOCUMENT id. They only match
  /// for the legacy shop whose doc id IS the bare UID. A shop's vehicles
  /// can therefore carry either id, so reads must match both: the
  /// argument itself, the `owner_id` of the shop doc with that id (cars
  /// written under the UID by old app versions), and the doc id of the
  /// shop whose `owner_id` is the argument (owner-side callers pass the
  /// UID). Every lookup fails soft to the argument alone, so an
  /// unreachable Firestore behaves exactly as before.
  Future<List<String>> _candidateShopIds(String shopId) async {
    final cached = _candidateShopIdsCache[shopId];
    if (cached != null) return cached;
    final ids = <String>{shopId};
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final doc = await fs.collection('shops').doc(shopId).get();
        final ownerId = doc.data()?['owner_id'] as String?;
        if (ownerId != null && ownerId.isNotEmpty) ids.add(ownerId);
      } catch (_) {}
      try {
        final owned = await fs
            .collection('shops')
            .where('owner_id', isEqualTo: shopId)
            .limit(1)
            .get();
        if (owned.docs.isNotEmpty) ids.add(owned.docs.first.id);
      } catch (_) {}
    }
    final result = ids.toList();
    _candidateShopIdsCache[shopId] = result;
    return result;
  }

  /// The shop DOCUMENT id a new vehicle for this shop must carry: the
  /// doc id of the shop owned by this UID, or the argument itself when
  /// no such shop exists (the legacy shop, whose doc id IS the UID).
  Future<String> _canonicalShopId(String shopId) async {
    final cached = _canonicalShopIdCache[shopId];
    if (cached != null) return cached;
    var result = shopId;
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final owned = await fs
            .collection('shops')
            .where('owner_id', isEqualTo: shopId)
            .limit(1)
            .get();
        if (owned.docs.isNotEmpty) result = owned.docs.first.id;
      } catch (_) {}
    }
    _canonicalShopIdCache[shopId] = result;
    return result;
  }

  Future<int> getActiveVehicleCount(String shopId) async {
    final ids = await _candidateShopIds(shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('vehicles')
            .where('shopId', whereIn: ids)
            .get();
        if (snap.docs.isNotEmpty) return snap.docs.length;
      } catch (_) {}
    }
    return _inMemoryVehicles.where((v) => ids.contains(v.shopId)).length;
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
    final ids = await _candidateShopIds(shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('vehicles')
            .where('shopId', whereIn: ids)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => VehicleModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _inMemoryVehicles.where((v) => ids.contains(v.shopId)).toList();
  }

  /// Customer discovery (F-M2, admin audit 2026-11-14): the shop's
  /// fleet as a customer sees it. Cars the admin hid or rejected
  /// (`car_reviews/{vehicleId}.status` == 'hidden' | 'rejected')
  /// are excluded — the same decision
  /// [AdminShopsDataSource.setCarReview] writes, mirrored onto the
  /// vehicle doc as `listing_status`. The plain [getShopVehicles]
  /// is deliberately NOT filtered: the owner still needs to see
  /// their own hidden/rejected cars (and existing bookings behind
  /// them) in the owner app.
  Future<List<VehicleEntity>> getCustomerShopVehicles(
      String shopId) async {
    final vehicles = await getShopVehicles(shopId);
    if (vehicles.isEmpty) return vehicles;
    final hidden = await _hiddenVehicleIds();
    if (hidden.isEmpty) return vehicles;
    return vehicles
        .where((v) => !hidden.contains(v.vehicleId))
        .toList();
  }

  /// Customer discovery, single car (F-M2): null when the admin hid
  /// or rejected this car, so a deep link / saved car cannot be
  /// opened and booked after moderation. Owner callers keep using
  /// [getVehicleById], which never hides.
  Future<VehicleEntity?> getCustomerVehicleById(String vehicleId) async {
    final hidden = await _hiddenVehicleIds();
    if (hidden.contains(vehicleId)) return null;
    return getVehicleById(vehicleId);
  }

  /// The ids of vehicles the admin hid or rejected, from the
  /// `car_reviews` decisions (the source of truth — deleting a
  /// review doc lifts the moderation). The `listing_status` mirror
  /// on the vehicle doc is a denormalised copy for future
  /// server-side queries, not read here. A failed read fails OPEN
  /// (empty set) — discovery must not strand every car on an
  /// outage; the admin panel still shows the review state.
  Future<Set<String>> _hiddenVehicleIds() async {
    final hidden = <String>{};
    final fs = _resolvedFirestore;
    if (fs == null) return hidden;
    try {
      final snap = await fs.collection('car_reviews').get();
      for (final d in snap.docs) {
        final status = d.data()['status'] as String?;
        if (status == 'hidden' || status == 'rejected') {
          hidden.add(d.id);
        }
      }
    } catch (_) {}
    return hidden;
  }

  /// Phase A (A1): fetch one vehicle by id from the top-level `vehicles`
  /// collection. The customer vehicle route needs this — the customer does
  /// not know the shop up front, so the owner's per-shop list cannot be
  /// used. Falls back to the in-memory sample fleet when Firestore is
  /// unreachable (tests / offline).
  Future<VehicleEntity?> getVehicleById(String vehicleId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final doc = await fs.collection('vehicles').doc(vehicleId).get();
        if (doc.exists && doc.data() != null) {
          return VehicleModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        // CU-M6: a failed read is not "not found" — the in-memory
        // copy still answers when offline, but when there is none
        // the error is rethrown so the caller can show an error
        // state with retry instead of a not-found screen. The two
        // owner callers already wrap this in try/catch, so their
        // behaviour is unchanged (a failure still reads as null).
        try {
          return _inMemoryVehicles.firstWhere((v) => v.vehicleId == vehicleId);
        } catch (_) {
          rethrow;
        }
      }
    }
    try {
      return _inMemoryVehicles.firstWhere((v) => v.vehicleId == vehicleId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addVehicle({
    required String shopId,
    required VehicleEntity vehicle,
  }) async {
    // Shop-id mismatch (2026-11-11): the caller passes the owner's UID,
    // but the vehicle must be stored under the shop DOCUMENT id or the
    // customer shop page never finds it. The stored model — Firestore
    // write, in-memory add and queued offline write alike — carries the
    // canonical id; writing `vehicle.shopId` verbatim would silently
    // undo the fix (this method's `shopId` parameter used to be
    // ignored entirely: `toMap()` carries the entity's own id).
    final canonicalShopId = await _canonicalShopId(shopId);
    final model =
        VehicleModel.fromEntity(vehicle).copyWith(shopId: canonicalShopId);
    _inMemoryVehicles.add(model);

    final written = await _writeVehicleDoc(
      vehicle.vehicleId,
      {
        ...model.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    if (!written) {
      await _queueVehicleWrite(vehicle.vehicleId, model.toMap());
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

    final fields = <String, dynamic>{'rates': ratesModel.toMap()};
    final written = await _writeVehicleDoc(vehicleId, fields);
    if (!written) await _queueVehicleWrite(vehicleId, fields);
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

    final fields = <String, dynamic>{'status': status};
    final written = await _writeVehicleDoc(vehicleId, fields);
    if (!written) await _queueVehicleWrite(vehicleId, fields);
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

    final fields = <String, dynamic>{'mileageKm': mileageKm};
    final written = await _writeVehicleDoc(vehicleId, fields);
    if (!written) await _queueVehicleWrite(vehicleId, fields);
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

    final map = model.toMap();
    // Firestore deletes a field on a null update value, so only
    // send the fields that are actually set.
    final update = <String, dynamic>{
      'rates': map['rates'],
      'packages': map['packages'] ?? [],
      'isSelfDriveAvailable': model.isSelfDriveAvailable,
      'isWithDriverAvailable': model.isWithDriverAvailable,
      if (map['weeklyRate'] != null) 'weeklyRate': map['weeklyRate'],
      if (map['monthlyRate'] != null) 'monthlyRate': map['monthlyRate'],
      if (map['customRates'] != null) 'customRates': map['customRates'],
      if (map['perKmPricingEnabled'] != null)
        'perKmPricingEnabled': map['perKmPricingEnabled'],
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
      if (map['homeCity'] != null) 'homeCity': map['homeCity'],
      if (map['homeCityRadiusKm'] != null)
        'homeCityRadiusKm': map['homeCityRadiusKm'],
      if (map['outCityMode'] != null) 'outCityMode': map['outCityMode'],
      if (map['outCityPerKmPkr'] != null)
        'outCityPerKmPkr': map['outCityPerKmPkr'],
      if (map['outCityFixedRouteId'] != null)
        'outCityFixedRouteId': map['outCityFixedRouteId'],
      if (map['driverNightStayPkr'] != null)
        'driverNightStayPkr': map['driverNightStayPkr'],
      if (map['tollsPaidBy'] != null) 'tollsPaidBy': map['tollsPaidBy'],
    };
    final written = await _writeVehicleDoc(vehicleId, update);
    if (!written) await _queueVehicleWrite(vehicleId, update);
  }

  /// Car-details edit: writes the identity subset only. The
  /// in-memory list gets the full updated entity; Firestore gets the
  /// same fields (the identity subset of `toMap`, so the document
  /// keeps its rates, packages and pricing policy untouched).
  Future<void> updateVehicleDetails({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) async {
    final model = VehicleModel.fromEntity(vehicle);
    final idx = _inMemoryVehicles.indexWhere((v) => v.vehicleId == vehicleId);
    if (idx != -1) {
      _inMemoryVehicles[idx] = model;
    }

    final map = model.toMap();
    // Firestore deletes a field on a null update value, so only
    // send the fields that are actually set.
    final update = <String, dynamic>{
      'make': model.make,
      'model': model.model,
      'year': model.year,
      'plateNumber': model.plateNumber,
      'category': model.category,
      'transmission': model.transmission,
      'fuelType': model.fuelType,
      'seats': model.seats,
      'features': model.features,
      'status': model.status,
      if (map['color'] != null) 'color': map['color'],
      if (map['imageUrl'] != null) 'imageUrl': map['imageUrl'],
    };
    final written = await _writeVehicleDoc(vehicleId, update);
    if (!written) await _queueVehicleWrite(vehicleId, update);
  }
}
