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
import 'admin_pagination.dart';

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

  /// Phase 4 (4.3) — client-side sort over a loaded list (the
  /// no-Firestore branch and the view's search results, which the
  /// server search returns unsorted). 'statusAsc' puts suspended
  /// first, then pending, then approved — the order an admin
  /// triages in.
  static List<ShopModel> sortShops(List<ShopModel> shops, String sort) {
    final list = List<ShopModel>.of(shops);
    switch (sort) {
      case 'nameDesc':
        list.sort((a, b) => b.shopName.compareTo(a.shopName));
      case 'statusAsc':
        int rank(ShopModel s) =>
            s.suspended ? 0 : s.verificationStatus == 'pending' ? 1 : 2;
        list.sort((a, b) {
          final r = rank(a).compareTo(rank(b));
          return r != 0 ? r : a.shopName.compareTo(b.shopName);
        });
      default:
        list.sort((a, b) => a.shopName.compareTo(b.shopName));
    }
    return list;
  }

  /// Phase 3 (3.4) — one page of the shops list, server-filtered by
  /// `statusFilter` ('all' | 'pending' | 'approved' | 'suspended').
  /// 'approved' means verified and not suspended; Firestore cannot
  /// express that in one query, so the page is filled by scanning
  /// verified shops in `shop_name` order and dropping the suspended
  /// ones (at most 1000 scanned, like the customers CNIC filter).
  /// The other filters are single queries: `verification_status` +
  /// `shop_name` and `suspended` + `shop_name` both have composite
  /// indexes in firestore.indexes.json.
  ///
  /// With no Firestore the page is cut from [getShops] in memory,
  /// so offline fakes that override [getShops] keep working; the
  /// cursor is then an integer offset.
  Future<AdminPage<ShopModel>> getShopsPage({
    int limit = 20,
    Object? cursor,
    String statusFilter = 'all',
    String sort = 'nameAsc',
  }) async {
    final firestore = _resolvedFirestore;
    final total = await countShops(statusFilter: statusFilter);
    if (firestore == null) {
      final all = sortShops(
          (await getShops())
              .where((s) => _matchesShopFilter(s, statusFilter))
              .toList(),
          sort);
      final offset = cursor is int ? cursor : 0;
      final page = all.skip(offset).take(limit).toList();
      return AdminPage(
        items: page,
        hasMore: offset + page.length < all.length,
        cursor: offset + page.length < all.length
            ? offset + page.length
            : null,
        total: all.length,
      );
    }
    if (statusFilter == 'approved') {
      final matched = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      DocumentSnapshot? lastDoc =
          cursor is DocumentSnapshot ? cursor : null;
      var scanned = 0;
      var exhausted = false;
      while (matched.length < limit && scanned < 1000 && !exhausted) {
        var query = firestore
            .collection('shops')
            .where('verification_status', isEqualTo: 'approved')
            .orderBy('shop_name', descending: sort == 'nameDesc')
            .limit(50);
        if (lastDoc != null) query = query.startAfterDocument(lastDoc);
        final snap = await query.get();
        if (snap.docs.isEmpty) {
          exhausted = true;
          break;
        }
        scanned += snap.docs.length;
        lastDoc = snap.docs.last;
        for (final d in snap.docs) {
          if (d.data()['suspended'] as bool? ?? false) continue;
          matched.add(d);
          if (matched.length >= limit) break;
        }
        if (snap.docs.length < 50) exhausted = true;
      }
      final items = matched
          .map((d) => ShopModel.fromMap(d.data(), id: d.id))
          .toList();
      return AdminPage(
        items: sort == 'statusAsc' ? sortShops(items, sort) : items,
        hasMore: !exhausted && scanned < 1000,
        cursor:
            !exhausted && scanned < 1000 ? lastDoc : null,
        total: total,
      );
    }
    // Phase 4 (4.3) — the sort is server-side: name A–Z / Z–A
    // orders by `shop_name`; status orders by
    // `verification_status` then name (composite indexes in
    // firestore.indexes.json; the suspended filter + status sort
    // needs the 3-field suspended/verification_status/shop_name
    // index). 'approved' is handled by the scan branch above,
    // which drops suspended rows — with a status sort the matched
    // page is re-sorted client-side below, suspended first.
    final descending = sort == 'nameDesc';
    var query = firestore.collection('shops').orderBy(
        sort == 'statusAsc' ? 'verification_status' : 'shop_name',
        descending: descending);
    if (sort == 'statusAsc') {
      query = query.orderBy('shop_name');
    }
    if (statusFilter == 'pending') {
      query = firestore
          .collection('shops')
          .where('verification_status', isEqualTo: 'pending')
          .orderBy(sort == 'statusAsc' ? 'verification_status' : 'shop_name',
              descending: descending);
      if (sort == 'statusAsc') query = query.orderBy('shop_name');
    } else if (statusFilter == 'suspended') {
      query = firestore
          .collection('shops')
          .where('suspended', isEqualTo: true)
          .orderBy(sort == 'statusAsc' ? 'verification_status' : 'shop_name',
              descending: descending);
      if (sort == 'statusAsc') query = query.orderBy('shop_name');
    }
    var paged = query.limit(limit + 1);
    final lastDoc = cursor is DocumentSnapshot ? cursor : null;
    if (lastDoc != null) paged = paged.startAfterDocument(lastDoc);
    final snap = await paged.get();
    final docs = snap.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    return AdminPage(
      items: pageDocs
          .map((d) => ShopModel.fromMap(d.data(), id: d.id))
          .toList(),
      hasMore: hasMore,
      cursor: hasMore ? pageDocs.last : null,
      total: total,
    );
  }

  bool _matchesShopFilter(ShopModel s, [String filter = 'all']) {
    return switch (filter) {
      'suspended' => s.suspended,
      'pending' => s.verificationStatus == 'pending',
      'approved' =>
        s.verificationStatus == 'approved' && !s.suspended,
      _ => true,
    };
  }

  /// Phase 3 (3.4) — how many shops the current filter matches in
  /// total, so the list can say "Showing first N of M". With no
  /// Firestore the count comes from [getShops] in memory.
  Future<int> countShops({String statusFilter = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return (await getShops())
          .where((s) => _matchesShopFilter(s, statusFilter))
          .length;
    }
    Future<int> countWhere(
        Query<Map<String, dynamic>> Function(
                CollectionReference<Map<String, dynamic>>)
            build) async {
      final count = await build(firestore.collection('shops')).count().get();
      return count.count ?? 0;
    }

    switch (statusFilter) {
      case 'pending':
        return countWhere(
            (c) => c.where('verification_status', isEqualTo: 'pending'));
      case 'suspended':
        return countWhere((c) => c.where('suspended', isEqualTo: true));
      case 'approved':
        // Verified minus verified-and-suspended: the count the
        // 'approved' page actually shows.
        final approved = await countWhere(
            (c) => c.where('verification_status', isEqualTo: 'approved'));
        final approvedSuspended = await countWhere((c) => c
            .where('verification_status', isEqualTo: 'approved')
            .where('suspended', isEqualTo: true));
        return approved - approvedSuspended;
      default:
        return countWhere((c) => c);
    }
  }

  /// Phase 3 (3.4) — server-side shop search: it covers the whole
  /// list, not just the loaded page. Firestore has no substring
  /// search, so the search scans the list in bounded pages (at most
  /// 500 shops) for a name / city / owner match — the same
  /// case-insensitive "contains" the old client-side search used,
  /// now over the collection instead of the loaded page. With no
  /// Firestore it filters [getShops] in memory.
  Future<List<ShopModel>> searchShops(
    String query, {
    int limit = 50,
  }) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return (await getShops())
          .where((s) =>
              s.shopName.toLowerCase().contains(needle) ||
              s.city.toLowerCase().contains(needle) ||
              (s.ownerName ?? '').toLowerCase().contains(needle))
          .take(limit)
          .toList();
    }
    try {
      final matched = <ShopModel>[];
      DocumentSnapshot? lastDoc;
      var scanned = 0;
      while (matched.length < limit && scanned < 500) {
        var pageQuery = firestore
            .collection('shops')
            .orderBy('shop_name')
            .limit(100);
        if (lastDoc != null) {
          pageQuery = pageQuery.startAfterDocument(lastDoc);
        }
        final snap = await pageQuery.get();
        if (snap.docs.isEmpty) break;
        scanned += snap.docs.length;
        lastDoc = snap.docs.last;
        for (final d in snap.docs) {
          final shop = ShopModel.fromMap(d.data(), id: d.id);
          if (shop.shopName.toLowerCase().contains(needle) ||
              shop.city.toLowerCase().contains(needle) ||
              (shop.ownerName ?? '').toLowerCase().contains(needle)) {
            matched.add(shop);
            if (matched.length >= limit) break;
          }
        }
        if (snap.docs.length < 100) break;
      }
      return matched;
    } catch (_) {
      return [];
    }
  }

  /// Phase 3 (3.4) — how many vehicles exist in total, so the cars
  /// list can say "Showing first N of M" at its 200 cap.
  Future<int> countCars() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return (await getCars()).length;
    final count =
        await firestore.collection('vehicles').count().get();
    return count.count ?? 0;
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
      // Phase 3 (3.3b) — status precondition: a shop that already
      // has a final decision cannot be re-decided. Only a pending
      // application, or one waiting on more info (the owner has
      // supplied it and it is back in the queue), can be approved
      // or rejected; an already-approved shop cannot be re-rejected
      // (and vice versa) without going through the proper status
      // path (suspend / a fresh application).
      final currentDoc =
          await firestore.collection('shops').doc(shopId).get();
      final currentData = currentDoc.data();
      if (currentData == null) return false;
      final currentStatus =
          (currentData['verification_status'] as String? ?? 'pending')
              .toLowerCase();
      if (currentStatus != 'pending' &&
          currentStatus != 'info_requested' &&
          currentStatus.isNotEmpty) {
        return false;
      }
      if (decision != 'approved' &&
          decision != 'info_requested' &&
          decision != 'rejected') {
        return false;
      }
      await firestore.collection('shops').doc(shopId).update({
        'verification_status': decision,
        'is_verified': decision == 'approved',
        if (decision == 'rejected') 'rejection_reason': reason,
        if (decision == 'info_requested') 'admin_note': reason,
        'reviewed_at': FieldValue.serverTimestamp(),
      });
      // Best-effort mirror onto the owner's users doc so their profile reflects verification.
      try {
        final ownerUid = (currentData['owner_id'] as String?) ??
            (currentData['ownerId'] as String?) ??
            (shopId.startsWith('shop_') ? shopId.substring(5) : '');
        if (ownerUid.isNotEmpty) {
          final ownerDoc =
              await firestore.collection('users').doc(ownerUid).get();
          if (ownerDoc.data() != null) {
            await firestore.collection('users').doc(ownerUid).update({
              'is_verified': decision == 'approved',
            });
          }
        }
      } catch (_) {}
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
      // Phase 3 (3.6c) — one batch: the review record and the
      // listing mirror land together, so a failure cannot leave the
      // decision recorded but the listing visible (or vice versa).
      final batch = firestore.batch();
      batch.set(
        firestore.collection('car_reviews').doc(vehicleId),
        {
          'vehicle_id': vehicleId,
          'status': status,
          'reason': reason,
          'reviewed_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.update(
        firestore.collection('vehicles').doc(vehicleId),
        {'listing_status': status},
      );
      await batch.commit();
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
