import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/utils/shop_id_resolution.dart';

import '../../domain/entities/finance_account_entity.dart';
import '../models/finance_account_model.dart';

/// Phase B (H1): the `finance_accounts` collection, Firestore-first
/// with an in-memory fallback. A shop always has at least the
/// default cash account, seeded on first read.
class FinanceAccountDataSource {
  final FirebaseFirestore? _firestore;
  final OfflineSyncQueue? syncQueue;
  final List<FinanceAccountModel> _inMemory = [];
  var _idSeq = 0;

  FinanceAccountDataSource({FirebaseFirestore? firestore, this.syncQueue})
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
    // Shop-id linking (2026-11-15): accounts must carry the shop
    // doc id; reads below match both forms via candidates.
    final canonical = await canonicalShopId(_resolvedFirestore, shopId);
    final id =
        'ACC-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final model = FinanceAccountModel(
      accountId: id,
      shopId: canonical,
      name: name.trim(),
      type: type,
      openingBalancePkr: openingBalancePkr,
      isDefault: isDefault,
    );
    _inMemory.add(model);
    final written = await _writeDoc('finance_accounts', id, model.toMap());
    if (!written) await _queueDoc('finance_accounts', id, model.toMap());
    return model;
  }

  Future<List<FinanceAccountEntity>> getShopAccounts(String shopId) async {
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('finance_accounts')
            .where('shopId', whereIn: ids)
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
        _inMemory.where((a) => ids.contains(a.shopId)).toList();
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
