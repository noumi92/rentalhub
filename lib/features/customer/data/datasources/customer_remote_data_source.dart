import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../domain/entities/customer_entity.dart';
import '../models/customer_model.dart';

/// Phase B (C1): customer records of a shop, from Firestore with an
/// in-memory fallback (offline / tests). Records are written when a
/// walk-in booking is made, when a CNIC is scanned, or when a
/// guarantor is added.
class CustomerRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final OfflineSyncQueue? syncQueue;
  final Map<String, CustomerModel> _inMemoryCustomers = {};

  CustomerRemoteDataSource({FirebaseFirestore? firestore, this.syncQueue})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Phase B (B1/B3): a failed Firestore write is queued (persisted)
  /// instead of dying in memory. Returns true when confirmed.
  Future<bool> _writeDoc(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      await fs.collection(collection).doc(docId).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _queueDoc(
    String collection,
    String docId,
    Map<String, dynamic> fields,
  ) async {
    final queue = syncQueue;
    if (queue == null) return;
    await queue.enqueue(
      kind: 'firestore_set',
      entityId: docId,
      payload: {
        'collection': collection,
        'docId': docId,
        'fields': fields,
      },
    );
  }

  /// Shop-id linking (2026-11-15): customers are written with the
  /// shop DOCUMENT id (`shop_<uid>`) while callers pass the bare
  /// owner UID, so a raw `shopId ==` query missed the shop's own
  /// customers. Match both id forms (Firestore `whereIn`, in-memory
  /// membership) — the same candidate pattern the fleet layer uses.
  /// [getCustomerByCnic] delegates here, so it is covered too.
  Future<List<CustomerEntity>> getShopCustomers(String shopId) async {
    final fs = _resolvedFirestore;
    final ids = await candidateShopIds(fs, shopId);
    if (fs != null) {
      try {
        final snap = await fs
            .collection('customers')
            .where('shopId', whereIn: ids)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => CustomerModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _inMemoryCustomers.values
        .where((c) => ids.contains(c.shopId))
        .toList();
  }

  /// C2: the signed-in customer's own record, by their uid (the doc id
  /// is the customer id — see [upsertCustomer]). Carries the name, phone
  /// and CNIC the booking request is filed under, so the review screen
  /// does not have to fall back to a placeholder identity.
  Future<CustomerEntity?> getCustomerById(String customerId) async {
    if (_inMemoryCustomers.containsKey(customerId)) {
      return _inMemoryCustomers[customerId];
    }
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final doc =
            await fs.collection('customers').doc(customerId).get();
        if (doc.exists && doc.data() != null) {
          return CustomerModel.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<CustomerEntity?> getCustomerByCnic(
      String shopId, String cnic) async {
    final clean = cnic.replaceAll('-', '').trim();
    final customers = await getShopCustomers(shopId);
    for (final c in customers) {
      final stored = c.cnic?.replaceAll('-', '').trim();
      if (stored != null && stored == clean) return c;
    }
    return null;
  }

  Future<void> upsertCustomer(CustomerEntity customer) async {
    // Shop-id linking (2026-11-15): callers pass the bare UID (CNIC
    // review) or the doc id (wizard); the stored record always
    // carries the canonical doc id. Canonicalizing an already
    // canonical id is a no-op.
    final canonical =
        await canonicalShopId(_resolvedFirestore, customer.shopId);
    final model =
        CustomerModel.fromEntity(customer.copyWith(shopId: canonical));
    _inMemoryCustomers[customer.customerId] = model;

    final written = await _writeDoc('customers', customer.customerId, model.toMap());
    if (!written) await _queueDoc('customers', customer.customerId, model.toMap());
  }

  /// Owner-deck finish (#35): owner approval of a customer profile.
  /// Writes only the approval fields (merge set, same [_writeDoc]
  /// pattern as [upsertCustomer]) so the rest of the record is
  /// untouched; a failed write is queued like any other. Approving
  /// clears a previous rejection reason (the field is written null).
  Future<void> updateApprovalStatus({
    required String customerId,
    required String status, // 'pending' | 'approved' | 'rejected'
    String? rejectionReason,
  }) async {
    final fields = <String, dynamic>{
      'approvalStatus': status,
      'rejectionReason': rejectionReason,
      'reviewedAt': DateTime.now().toIso8601String(),
    };
    final existing = _inMemoryCustomers[customerId];
    if (existing != null) {
      _inMemoryCustomers[customerId] =
          CustomerModel.fromMap({...existing.toMap(), ...fields}, customerId);
    }
    final written = await _writeDoc('customers', customerId, fields);
    if (!written) await _queueDoc('customers', customerId, fields);
  }

  /// Walk-in customer CRM: per-shop status of a customer.
  /// Customer docs are CNIC-keyed globally (one doc per CNIC shared
  /// across shops), so the status lives in the `shopStatuses` map
  /// keyed by shop DOCUMENT id. Writes only this shop's entry, as a
  /// dotted-key merge set (same [_writeDoc] pattern as
  /// [updateApprovalStatus]) so other shops' entries are untouched;
  /// a failed write is queued like any other and the
  /// [FirestoreSetHandler] replays the same dotted-key fields with
  /// merge semantics. The in-memory copy cannot take a dotted key
  /// (fromMap would ignore it), so it is rebuilt from a merged map.
  /// Throws [ArgumentError] for any status outside
  /// 'active' | 'blocked' | 'archived'.
  Future<void> updateCustomerStatus({
    required String customerId,
    required String shopId,
    required String status,
  }) async {
    if (status != CustomerEntity.statusActive &&
        status != CustomerEntity.statusBlocked &&
        status != CustomerEntity.statusArchived) {
      throw ArgumentError.value(
        status,
        'status',
        "must be one of 'active', 'blocked' or 'archived'",
      );
    }
    final fields = <String, dynamic>{'shopStatuses.$shopId': status};
    final existing = _inMemoryCustomers[customerId];
    if (existing != null) {
      final merged = {...?existing.shopStatuses, shopId: status};
      _inMemoryCustomers[customerId] = CustomerModel.fromMap(
        {...existing.toMap(), 'shopStatuses': merged},
        customerId,
      );
    }
    final written = await _writeDoc('customers', customerId, fields);
    if (!written) await _queueDoc('customers', customerId, fields);
  }

  /// Walk-in customer CRM: delete = archive. There is no hard
  /// delete for customers; archiving hides the customer from the
  /// shop's list while the record stays.
  Future<void> archiveCustomer({
    required String customerId,
    required String shopId,
  }) =>
      updateCustomerStatus(
        customerId: customerId,
        shopId: shopId,
        status: CustomerEntity.statusArchived,
      );
}
