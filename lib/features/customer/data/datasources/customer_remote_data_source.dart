import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer_entity.dart';
import '../models/customer_model.dart';

/// Phase B (C1): customer records of a shop, from Firestore with an
/// in-memory fallback (offline / tests). Records are written when a
/// walk-in booking is made, when a CNIC is scanned, or when a
/// guarantor is added.
class CustomerRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final Map<String, CustomerModel> _inMemoryCustomers = {};

  CustomerRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
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

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs
            .collection('customers')
            .doc(customer.customerId)
            .set(model.toMap());
      } catch (_) {}
    }
  }
}
