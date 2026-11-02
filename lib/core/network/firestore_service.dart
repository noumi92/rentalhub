import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../error/exceptions.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/discovery/data/models/shop_model.dart';
import '../../features/fleet/data/models/vehicle_model.dart';

/// Centralized Firestore service for RentalHub managing users, shops, vehicles, and bookings.
/// Falls back to an in-memory store when Firestore is uninitialized or in test environments.
class FirestoreService {
  final FirebaseFirestore? _firestore;
  final Map<String, Map<String, dynamic>> _inMemoryUsers = {};
  final Map<String, Map<String, dynamic>> _inMemoryShops = {};
  final Map<String, Map<String, dynamic>> _inMemoryVehicles = {};
  final Map<String, Map<String, dynamic>> _inMemoryBookings = {};

  FirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore;

  bool get _hasLiveFirestore => _firestore != null;

  // ================= USERS =================

  Future<void> saveUser(UserModel user) async {
    try {
      if (_hasLiveFirestore) {
        await _firestore!.collection('users').doc(user.uid).set(
              user.toMap(),
              SetOptions(merge: true),
            );
      } else {
        _inMemoryUsers[user.uid] = user.toMap();
      }
    } catch (e) {
      debugPrint('Firestore saveUser error: $e');
      _inMemoryUsers[user.uid] = user.toMap();
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      if (_hasLiveFirestore) {
        final doc = await _firestore!.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, id: doc.id);
        }
      }
    } catch (e) {
      debugPrint('Firestore getUser error: $e');
    }

    if (_inMemoryUsers.containsKey(uid)) {
      return UserModel.fromMap(_inMemoryUsers[uid]!, id: uid);
    }
    return null;
  }

  // ================= SHOPS =================

  Future<void> saveShop(ShopModel shop) async {
    try {
      if (_hasLiveFirestore) {
        await _firestore!.collection('shops').doc(shop.shopId).set(
              shop.toMap(),
              SetOptions(merge: true),
            );
      } else {
        _inMemoryShops[shop.shopId] = shop.toMap();
      }
    } catch (e) {
      debugPrint('Firestore saveShop error: $e');
      _inMemoryShops[shop.shopId] = shop.toMap();
    }
  }

  Future<ShopModel?> getShop(String shopId) async {
    try {
      if (_hasLiveFirestore) {
        final doc = await _firestore!.collection('shops').doc(shopId).get();
        if (doc.exists && doc.data() != null) {
          return ShopModel.fromMap(doc.data()!, id: doc.id);
        }
      }
    } catch (e) {
      debugPrint('Firestore getShop error: $e');
    }

    if (_inMemoryShops.containsKey(shopId)) {
      return ShopModel.fromMap(_inMemoryShops[shopId]!, id: shopId);
    }
    return null;
  }

  Future<List<ShopModel>> getNearbyShops({required String city}) async {
    try {
      if (_hasLiveFirestore) {
        final query = await _firestore!
            .collection('shops')
            .where('city', isEqualTo: city)
            .where('is_verified', isEqualTo: true)
            .get();

        if (query.docs.isNotEmpty) {
          return query.docs
              .map((d) => ShopModel.fromMap(d.data(), id: d.id))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Firestore getNearbyShops error: $e');
    }

    return _inMemoryShops.values
        .map((d) => ShopModel.fromMap(d, id: d['shop_id']))
        .toList();
  }

  // ================= VEHICLES =================

  Future<void> saveVehicle(VehicleModel vehicle) async {
    try {
      if (_hasLiveFirestore) {
        final ratesMap = (vehicle.rates as VehicleRatesModel).toMap();
        final data = {
          'vehicle_id': vehicle.vehicleId,
          'shop_id': vehicle.shopId,
          'make': vehicle.make,
          'model': vehicle.model,
          'year': vehicle.year,
          'plate_number': vehicle.plateNumber,
          'category': vehicle.category,
          'transmission': vehicle.transmission,
          'fuel_type': vehicle.fuelType,
          'seats': vehicle.seats,
          'status': vehicle.status,
          'rates': ratesMap,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await _firestore!.collection('vehicles').doc(vehicle.vehicleId).set(
              data,
              SetOptions(merge: true),
            );
      } else {
        final ratesMap = (vehicle.rates as VehicleRatesModel).toMap();
        _inMemoryVehicles[vehicle.vehicleId] = {
          'vehicle_id': vehicle.vehicleId,
          'shop_id': vehicle.shopId,
          'make': vehicle.make,
          'model': vehicle.model,
          'year': vehicle.year,
          'plate_number': vehicle.plateNumber,
          'category': vehicle.category,
          'transmission': vehicle.transmission,
          'fuel_type': vehicle.fuelType,
          'seats': vehicle.seats,
          'status': vehicle.status,
          'rates': ratesMap,
        };
      }
    } catch (e) {
      debugPrint('Firestore saveVehicle error: $e');
    }
  }

  Future<List<VehicleModel>> getShopVehicles(String shopId) async {
    try {
      if (_hasLiveFirestore) {
        final query = await _firestore!
            .collection('vehicles')
            .where('shop_id', isEqualTo: shopId)
            .get();

        return query.docs.map((doc) {
          final d = doc.data();
          return VehicleModel(
            vehicleId: doc.id,
            shopId: d['shop_id'] ?? '',
            make: d['make'] ?? '',
            model: d['model'] ?? '',
            year: d['year'] ?? 2022,
            plateNumber: d['plate_number'] ?? '',
            category: d['category'] ?? 'Sedan',
            transmission: d['transmission'] ?? 'Automatic',
            fuelType: d['fuel_type'] ?? 'Petrol',
            seats: d['seats'] ?? 5,
            rates: VehicleRatesModel.fromMap(
                Map<String, dynamic>.from(d['rates'] ?? {})),
            status: d['status'] ?? 'Available',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Firestore getShopVehicles error: $e');
    }

    return _inMemoryVehicles.values
        .where((v) => v['shop_id'] == shopId)
        .map((d) => VehicleModel(
              vehicleId: d['vehicle_id'] ?? '',
              shopId: d['shop_id'] ?? '',
              make: d['make'] ?? '',
              model: d['model'] ?? '',
              year: d['year'] ?? 2022,
              plateNumber: d['plate_number'] ?? '',
              category: d['category'] ?? 'Sedan',
              transmission: d['transmission'] ?? 'Automatic',
              fuelType: d['fuel_type'] ?? 'Petrol',
              seats: d['seats'] ?? 5,
              rates: VehicleRatesModel.fromMap(
                  Map<String, dynamic>.from(d['rates'] ?? {})),
              status: d['status'] ?? 'Available',
            ))
        .toList();
  }

  // ================= CONCURRENT BOOKINGS =================

  /// Creates a booking with concurrency lock protection against double-booking.
  Future<void> createBookingLock({
    required String bookingId,
    required String vehicleId,
    required String customerId,
    required Map<String, dynamic> bookingData,
  }) async {
    if (_hasLiveFirestore) {
      final bookingRef = _firestore!.collection('bookings').doc(bookingId);
      final vehicleRef = _firestore.collection('vehicles').doc(vehicleId);

      await _firestore.runTransaction((transaction) async {
        final vSnapshot = await transaction.get(vehicleRef);
        if (!vSnapshot.exists) {
          throw const ServerException(message: 'Vehicle not found');
        }

        final status = vSnapshot.data()?['status'] ?? 'Available';
        if (status == 'Rented' || status == 'Reserved') {
          throw const ServerException(
            message: 'Vehicle is currently locked by another reservation or on rent.',
          );
        }

        // Lock vehicle
        transaction.update(vehicleRef, {'status': 'Reserved'});
        transaction.set(bookingRef, {
          ...bookingData,
          'booking_id': bookingId,
          'vehicle_id': vehicleId,
          'customer_id': customerId,
          'created_at': DateTime.now().toIso8601String(),
        });
      });
    } else {
      // In-memory simulation
      final v = _inMemoryVehicles[vehicleId];
      if (v != null && (v['status'] == 'Rented' || v['status'] == 'Reserved')) {
        throw const ServerException(
          message: 'Vehicle is currently locked by another reservation or on rent.',
        );
      }
      if (v != null) v['status'] = 'Reserved';
      _inMemoryBookings[bookingId] = {
        ...bookingData,
        'booking_id': bookingId,
        'vehicle_id': vehicleId,
        'customer_id': customerId,
      };
    }
  }
}

