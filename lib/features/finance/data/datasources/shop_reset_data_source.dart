import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/shop_id_resolution.dart';

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
  static const _bookedSlots = 'vehicle_booked_slots';
  static const _agreements = 'agreements';
  static const _handovers = 'handovers';
  static const _returnSettlements = 'return_settlements';
  static const _securityDeposits = 'security_deposits';
  static const _customers = 'customers';
  static const _vehicles = 'vehicles';
  static const _fixedRoutes = 'fixed_routes';
  static const _financeCollections = [
    'finance_transfers',
    'finance_accounts',
    'finance_categories',
    'cash_closings',
    'partner_shares',
  ];
  static const _staff = 'staff';

  Future<int> resetBookings(String shopId) async {
    var total = 0;
    total += await _deleteWhere(_bookings, shopId);
    total += await _deleteWhere(_bookedSlots, shopId);
    total += await _deleteWhere(_agreements, shopId);
    total += await _deleteWhere(_handovers, shopId);
    total += await _deleteWhere(_returnSettlements, shopId);
    total += await _deleteWhere(_securityDeposits, shopId);
    return total;
  }

  Future<int> resetCustomers(String shopId) =>
      _deleteWhere(_customers, shopId);

  Future<int> resetCars(String shopId) async {
    var total = 0;
    total += await _deleteWhere(_vehicles, shopId);
    total += await _deleteWhere(_fixedRoutes, shopId);
    return total;
  }

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
    // Shop-id linking (2026-11-15): a reset must delete both id
    // forms AND both camelCase (`shopId`) and snake_case (`shop_id`)
    // field names so no shop-owned document survives the wipe.
    final fs = _fs;
    final ids = await candidateShopIds(fs, shopId);
    if (ids.isEmpty) return 0;
    var deleted = 0;
    for (final field in const ['shopId', 'shop_id']) {
      while (true) {
        final snap = await fs
            .collection(collection)
            .where(field, whereIn: ids)
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
    }
    return deleted;
  }
}
