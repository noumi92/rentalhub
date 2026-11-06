import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/finance_account_entity.dart';
import '../models/finance_account_model.dart';

/// Phase B (H1): the `finance_accounts` collection, Firestore-first
/// with an in-memory fallback. A shop always has at least the
/// default cash account, seeded on first read.
class FinanceAccountDataSource {
  final FirebaseFirestore? _firestore;
  final List<FinanceAccountModel> _inMemory = [];
  var _idSeq = 0;

  FinanceAccountDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<FinanceAccountEntity> saveAccount({
    required String shopId,
    required String name,
    required String type,
    int openingBalancePkr = 0,
    bool isDefault = false,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Account name is required');
    }
    const allowed = {'cash', 'bank', 'jazzcash', 'easypaisa'};
    if (!allowed.contains(type)) {
      throw ArgumentError('Unknown account type: $type');
    }
    final id =
        'ACC-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final model = FinanceAccountModel(
      accountId: id,
      shopId: shopId,
      name: name.trim(),
      type: type,
      openingBalancePkr: openingBalancePkr,
      isDefault: isDefault,
    );
    _inMemory.add(model);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('finance_accounts').doc(id).set(model.toMap());
      } catch (_) {}
    }
    return model;
  }

  Future<List<FinanceAccountEntity>> getShopAccounts(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('finance_accounts')
            .where('shopId', isEqualTo: shopId)
            .get();
        for (final d in snap.docs) {
          final remote = FinanceAccountModel.fromMap(d.data());
          if (!_inMemory
              .any((m) => m.accountId == remote.accountId)) {
            _inMemory.add(remote);
          }
        }
      } catch (_) {}
    }
    List<FinanceAccountEntity> mine =
        _inMemory.where((a) => a.shopId == shopId).toList();
    if (mine.isEmpty) {
      // Every shop starts with a cash account, so the ledger always
      // has somewhere to post.
      final cash = await saveAccount(
        shopId: shopId,
        name: 'Cash in Hand',
        type: 'cash',
        isDefault: true,
      );
      mine = [cash];
    }
    return mine;
  }
}
