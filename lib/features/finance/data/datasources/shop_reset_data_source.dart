import 'package:cloud_firestore/cloud_firestore.dart';

/// Audit impl (O50): dangerous, shop-scoped deletes for the Reset
/// Options screen. Every delete is filtered by the current shop's
/// id, so one shop can never wipe another shop's data. Firestore is
/// resolved lazily; without it the call fails honestly instead of
/// pretending the data is gone.
class ShopResetDataSource {
  final FirebaseFirestore? _firestore;

  ShopResetDataSource({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _fs {
    final fs = _firestore ??
        (() {
          try {
            return FirebaseFirestore.instance;
          } catch (_) {
            return null;
          }
        })();
    if (fs == null) throw StateError('Firestore is not available');
    return fs;
  }

  static const _bookings = 'bookings';
  static const _customers = 'customers';
  static const _vehicles = 'vehicles';
  static const _financeCollections = [
    'finance_transfers',
    'finance_accounts',
    'finance_categories',
  ];
  static const _staff = 'staff';

  Future<int> resetBookings(String shopId) =>
      _deleteWhere(_bookings, shopId);

  Future<int> resetCustomers(String shopId) =>
      _deleteWhere(_customers, shopId);

  Future<int> resetCars(String shopId) => _deleteWhere(_vehicles, shopId);

  /// Everything above, plus the shop's finance ledger, accounts,
  /// categories and staff. Shop settings and the shop document
  /// itself are never deleted — the shop stays, its data goes.
  Future<int> resetAll(String shopId) async {
    var total = 0;
    total += await resetBookings(shopId);
    total += await resetCustomers(shopId);
    total += await resetCars(shopId);
    for (final collection in _financeCollections) {
      total += await _deleteWhere(collection, shopId);
    }
    total += await _deleteWhere(_staff, shopId);
    return total;
  }

  Future<int> _deleteWhere(String collection, String shopId) async {
    final fs = _fs;
    var deleted = 0;
    while (true) {
      final snap = await fs
          .collection(collection)
          .where('shopId', isEqualTo: shopId)
          .limit(400)
          .get();
      if (snap.docs.isEmpty) break;
      final batch = fs.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += snap.docs.length;
    }
    return deleted;
  }
}
