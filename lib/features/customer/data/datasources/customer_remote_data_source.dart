import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
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

  Future<List<CustomerEntity>> getShopCustomers(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('customers')
            .where('shopId', isEqualTo: shopId)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => CustomerModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _inMemoryCustomers.values
        .where((c) => c.shopId == shopId)
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
    final model = CustomerModel.fromEntity(customer);
    _inMemoryCustomers[customer.customerId] = model;

    final written = await _writeDoc('customers', customer.customerId, model.toMap());
    if (!written) await _queueDoc('customers', customer.customerId, model.toMap());
  }
}
