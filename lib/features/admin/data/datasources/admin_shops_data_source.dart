import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/shop_id_resolution.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../../fleet/data/models/vehicle_model.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../services/admin_session.dart';
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
  ///
  /// F-M6: a failed read throws — the approvals view shows its error
  /// state instead of "No pending applications" during an outage.
  /// `[]` is returned only with no Firestore (tests).
  Future<List<ShopModel>> getPendingShops() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    final snap = await firestore
        .collection('shops')
        .where('verification_status', isEqualTo: 'pending')
        .get();
    return snap.docs
        .map((d) => ShopModel.fromMap(d.data(), id: d.id))
        .toList();
  }

  /// F-M6: a failed read throws (see [getPendingShops]).
  Future<List<ShopModel>> getShops() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    final snap = await firestore
        .collection('shops')
        .orderBy('shop_name')
        .limit(200)
        .get();
    return snap.docs
        .map((d) => ShopModel.fromMap(d.data(), id: d.id))
        .toList();
  }

  /// F-M6: throws on a failed read; null only when the doc is
  /// missing (the detail view shows "not found").
  Future<ShopModel?> getShop(String shopId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    final doc = await firestore.collection('shops').doc(shopId).get();
    final data = doc.data();
    if (data == null) return null;
    return ShopModel.fromMap(data, id: doc.id);
  }

  /// F-M6: throws on a failed read; 0 only with no Firestore.
  Future<int> getShopVehicleCount(String shopId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return 0;
    final ids = await candidateShopIds(firestore, shopId);
    final snap = await firestore
        .collection('vehicles')
        .where('shopId', whereIn: ids)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// F-M6: throws on a failed read; 0 only with no Firestore.
  Future<int> getShopBookingCount(String shopId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return 0;
    final ids = await candidateShopIds(firestore, shopId);
    final snap = await firestore
        .collection('bookings')
        .where('shopId', whereIn: ids)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// The shop's WhatsApp credits balance (F-m7), from the real
  /// `whatsapp_credits/{shopId}` document the owner credits screen
  /// reads. Null when no credits document exists (or it cannot be
  /// read) — the detail screen says "no record yet" instead of
  /// showing a 0 that was never stored.
  Future<int?> getShopCreditsBalance(String shopId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore
          .collection('whatsapp_credits')
          .doc(await canonicalShopId(firestore, shopId))
          .get();
      final data = doc.data();
      if (data == null) return null;
      return (data['balance'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Approve / ask for more info / reject a shop application.
  /// Decision values: 'approved' | 'info_requested' | 'rejected'.
  ///
  /// F-M3 (admin audit 2026-11-14): the reason used to be written to
  /// the shops doc and read by nobody. The decision is now also
  /// delivered to the owner as an in-app notification on the shop's
  /// own inbox (`notifications`, read by the owner dashboard /
  /// notifications screen), carrying the decision and the reason —
  /// no WhatsApp send is invented here (gated on plan D2). The
  /// reason stays readable on the shop doc itself
  /// (`rejection_reason` / `admin_note`, see [ShopModel]).
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// decideVendor]). The caller's role is passed by the view when
  /// it already resolved it, otherwise resolved from the session
  /// here; an unresolvable role refuses the write (fail closed).
  Future<bool> decideShopApplication({
    required String shopId,
    required String decision,
    String reason = '',
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.decideVendor,
        adminRole: adminRole)) {
      return false;
    }
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
      try {
        await NotificationDataSource(firestore: firestore)
            .createNotification(
          shopId: shopId,
          title: 'Shop application decided',
          body: decision == 'approved'
              ? 'Your shop application was approved.'
              : decision == 'rejected'
                  ? 'Your shop application was rejected.'
                      '${reason.isNotEmpty ? ' Reason: $reason' : ''}'
                  : 'The admin asked for more information about your shop'
                      ' application.'
                      '${reason.isNotEmpty ? ' $reason' : ''}',
          type: 'shop_application_decided',
        );
      } catch (_) {
        // The decision itself stands; a failed notification must not
        // report the decision as failed (same rule as the audit log).
      }
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
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// decideVendor]) — see [decideShopApplication].
  Future<bool> setShopSuspended({
    required String shopId,
    required bool suspended,
    required String reason,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.decideVendor,
        adminRole: adminRole)) {
      return false;
    }
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

  /// F-M6: a failed read throws (see [getPendingShops]).
  Future<List<VehicleEntity>> getCars() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    final snap = await firestore
        .collection('vehicles')
        .orderBy('make')
        .limit(200)
        .get();
    return snap.docs
        .map((d) => VehicleModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// The admin car-approval state, one doc per vehicle in `car_reviews`.
  /// Null when the car has never been reviewed. F-M6: throws on a
  /// failed read instead of returning null (which reads as "never
  /// reviewed").
  Future<CarReview?> getCarReview(String vehicleId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    final doc =
        await firestore.collection('car_reviews').doc(vehicleId).get();
    final data = doc.data();
    if (data == null) return null;
    return CarReview.fromMap(vehicleId, data);
  }

  /// F-M6: a failed read throws (see [getPendingShops]).
  Future<Map<String, CarReview>> getCarReviews() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return {};
    final snap = await firestore.collection('car_reviews').get();
    return {
      for (final d in snap.docs)
        d.id: CarReview.fromMap(d.id, d.data()),
    };
  }

  /// Approve / hide / reject a car listing (B3).
  /// Status values: 'approved' | 'hidden' | 'rejected'.
  ///
  /// F-M2 (admin audit 2026-11-14): the decision used to live only
  /// in `car_reviews/{vehicleId}`, which no customer-facing query
  /// read — a hidden/rejected car stayed discoverable. The decision
  /// is now mirrored onto the vehicle document itself
  /// (`listing_status`), and the customer discovery reads
  /// ([FleetRemoteDataSource.getCustomerShopVehicles] /
  /// [getCustomerVehicleById]) filter on the `car_reviews` decision,
  /// so a car hidden or rejected after the mirror was written — or
  /// one whose mirror write was missed — still disappears.
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// decideVendor]) — see [decideShopApplication].
  Future<bool> setCarReview({
    required String vehicleId,
    required String status,
    required String reason,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.decideVendor,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('car_reviews').doc(vehicleId).set({
        'vehicle_id': vehicleId,
        'status': status,
        'reason': reason,
        'reviewed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await firestore.collection('vehicles').doc(vehicleId).update({
        'listing_status': status,
      });
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

  factory ShopApplicationChecklist.fromShop(ShopModel shop,
      [AppLocalizations? l10n]) {
    return ShopApplicationChecklist([
      (
        label: l10n?.admin2_checklistShopName ?? 'Shop name and address',
        done: shop.shopName.trim().isNotEmpty &&
            shop.address.trim().isNotEmpty,
      ),
      (
        label: l10n?.admin2_checklistOwnerPhone ?? 'Owner phone number',
        done: shop.phoneNumber.trim().isNotEmpty,
      ),
      (
        label: l10n?.admin2_checklistOwnerCnic ?? 'Owner CNIC on file',
        done: (shop.cnicNumber ?? '').trim().isNotEmpty,
      ),
      (
        label: l10n?.admin2_checklistKyc ?? 'KYC documents uploaded',
        done: shop.kycDocuments.isNotEmpty,
      ),
      (
        label: l10n?.admin2_checklistBank ?? 'Bank / wallet account on file',
        done: shop.bankAccounts.isNotEmpty,
      ),
      (
        label: l10n?.admin2_checklistFleet ?? 'Fleet photos uploaded',
        done: shop.fleetPhotos.isNotEmpty,
      ),
    ]);
  }
}
