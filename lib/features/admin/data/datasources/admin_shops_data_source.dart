import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../discovery/data/models/shop_model.dart';
import '../../../fleet/data/models/vehicle_model.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../services/admin_audit_service.dart';

/// Phase B — the shops side of the admin panel: the approvals queue,
/// the shops list, and the cars list.
///
/// The approvals queue reads the real pending shops: a shop's
/// application IS its `shops` document (`verification_status ==
/// 'pending'`), so there is no separate `shop_applications` collection
/// with no writer — the plan's B1 text was corrected to this at build
/// time. Decisions write back to the shops doc and are audit-logged;
/// write methods return whether the cloud write actually happened, so
/// a view never claims a decision that only lived on the device.
class AdminShopsDataSource {
  final FirebaseFirestore? _firestore;

  AdminShopsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Shops waiting for approval (verification_status 'pending').
  Future<List<ShopModel>> getPendingShops() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('shops')
          .where('verification_status', isEqualTo: 'pending')
          .get();
      return snap.docs
          .map((d) => ShopModel.fromMap(d.data(), id: d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ShopModel>> getShops() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('shops')
          .orderBy('shop_name')
          .limit(200)
          .get();
      return snap.docs
          .map((d) => ShopModel.fromMap(d.data(), id: d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ShopModel?> getShop(String shopId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore.collection('shops').doc(shopId).get();
      final data = doc.data();
      if (data == null) return null;
      return ShopModel.fromMap(data, id: doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<int> getShopVehicleCount(String shopId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return 0;
    try {
      final snap = await firestore
          .collection('vehicles')
          .where('shopId', isEqualTo: shopId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getShopBookingCount(String shopId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return 0;
    try {
      final snap = await firestore
          .collection('bookings')
          .where('shopId', isEqualTo: shopId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Approve / ask for more info / reject a shop application.
  /// Decision values: 'approved' | 'info_requested' | 'rejected'.
  Future<bool> decideShopApplication({
    required String shopId,
    required String decision,
    String reason = '',
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('shops').doc(shopId).update({
        'verification_status': decision,
        'is_verified': decision == 'approved',
        if (decision == 'rejected') 'rejection_reason': reason,
        if (decision == 'info_requested') 'admin_note': reason,
        'reviewed_at': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action: 'shop_application_$decision',
        targetType: 'shop',
        targetId: shopId,
        detail: reason,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Suspend / unsuspend a shop (B2). The reason is stored on the doc.
  Future<bool> setShopSuspended({
    required String shopId,
    required bool suspended,
    required String reason,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('shops').doc(shopId).update({
        'suspended': suspended,
        'suspension_reason': suspended ? reason : null,
      });
      await AdminAuditService.logAction(
        action: suspended ? 'shop_suspended' : 'shop_unsuspended',
        targetType: 'shop',
        targetId: shopId,
        detail: reason,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<VehicleEntity>> getCars() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('vehicles')
          .orderBy('make')
          .limit(200)
          .get();
      return snap.docs
          .map((d) => VehicleModel.fromMap(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// The admin car-approval state, one doc per vehicle in `car_reviews`.
  /// Null when the car has never been reviewed.
  Future<CarReview?> getCarReview(String vehicleId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final doc =
          await firestore.collection('car_reviews').doc(vehicleId).get();
      final data = doc.data();
      if (data == null) return null;
      return CarReview.fromMap(vehicleId, data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, CarReview>> getCarReviews() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return {};
    try {
      final snap = await firestore.collection('car_reviews').get();
      return {
        for (final d in snap.docs)
          d.id: CarReview.fromMap(d.id, d.data()),
      };
    } catch (_) {
      return {};
    }
  }

  /// Approve / hide / reject a car listing (B3).
  /// Status values: 'approved' | 'hidden' | 'rejected'.
  Future<bool> setCarReview({
    required String vehicleId,
    required String status,
    required String reason,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('car_reviews').doc(vehicleId).set({
        'vehicle_id': vehicleId,
        'status': status,
        'reason': reason,
        'reviewed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await AdminAuditService.logAction(
        action: 'car_review_$status',
        targetType: 'vehicle',
        targetId: vehicleId,
        detail: reason,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// One car-approval record (B3): the admin's decision on a vehicle
/// listing, stored in `car_reviews/{vehicleId}`.
class CarReview {
  const CarReview({
    required this.vehicleId,
    required this.status,
    required this.reason,
    this.reviewedAt,
  });

  final String vehicleId;
  final String status;
  final String reason;
  final DateTime? reviewedAt;

  factory CarReview.fromMap(String vehicleId, Map<String, dynamic> data) {
    final reviewed = data['reviewed_at'];
    DateTime? reviewedAt;
    if (reviewed is Timestamp) {
      reviewedAt = reviewed.toDate();
    } else if (reviewed is String) {
      reviewedAt = DateTime.tryParse(reviewed);
    }
    return CarReview(
      vehicleId: vehicleId,
      status: data['status'] as String? ?? 'pending',
      reason: data['reason'] as String? ?? '',
      reviewedAt: reviewedAt,
    );
  }
}

/// The B1 approvals checklist, computed from the shop document itself:
/// six items, each present or missing. Nothing here is invented — an
/// item is done only when the field exists on the doc.
class ShopApplicationChecklist {
  const ShopApplicationChecklist(this.items);

  final List<({String label, bool done})> items;

  int get doneCount => items.where((i) => i.done).length;

  factory ShopApplicationChecklist.fromShop(ShopModel shop) {
    return ShopApplicationChecklist([
      (
        label: 'Shop name and address',
        done: shop.shopName.trim().isNotEmpty &&
            shop.address.trim().isNotEmpty,
      ),
      (
        label: 'Owner phone number',
        done: shop.phoneNumber.trim().isNotEmpty,
      ),
      (
        label: 'Owner CNIC on file',
        done: (shop.cnicNumber ?? '').trim().isNotEmpty,
      ),
      (
        label: 'KYC documents uploaded',
        done: shop.kycDocuments.isNotEmpty,
      ),
      (
        label: 'Bank / wallet account on file',
        done: shop.bankAccounts.isNotEmpty,
      ),
      (
        label: 'Fleet photos uploaded',
        done: shop.fleetPhotos.isNotEmpty,
      ),
    ]);
  }
}
