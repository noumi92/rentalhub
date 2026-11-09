import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../domain/entities/finance_transfer_entity.dart';
import '../models/finance_transfer_model.dart';

/// Phase B (H1/H2): the `finance_transfers` ledger, Firestore-first
/// with an in-memory fallback.
class FinanceTransferDataSource {
  final FirebaseFirestore? _firestore;

  /// Phase B (B1/B3): the persisted pending-write store. When set,
  /// a failed Firestore write is queued instead of dying in memory.
  final OfflineSyncQueue? syncQueue;

  final List<FinanceTransferModel> _inMemory = [];
  var _idSeq = 0;

  FinanceTransferDataSource({FirebaseFirestore? firestore, this.syncQueue})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<FinanceTransferEntity> addTransfer({
    required String shopId,
    required String accountId,
    required String kind,
    required String category,
    required int amountPkr,
    String? bookingId,
    String? vehicleId,
    String? customerId,
    String? note,
    String? paymentMethod,
    DateTime? createdAt,
  }) async {
    if (kind != 'income' && kind != 'expense') {
      throw ArgumentError("kind must be 'income' or 'expense'");
    }
    if (amountPkr <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }
    final id =
        'TRF-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final model = FinanceTransferModel(
      transferId: id,
      shopId: shopId,
      accountId: accountId,
      kind: kind,
      category: category,
      amountPkr: amountPkr,
      bookingId: bookingId,
      vehicleId: vehicleId,
      customerId: customerId,
      note: note,
      paymentMethod: paymentMethod,
      createdAt: createdAt ?? DateTime.now(),
    );
    _inMemory.add(model);
    // Phase B (B1/B4): merge-set + server timestamp; on failure the
    // transfer is queued (persisted) — a money record must never
    // live only in memory.
    final fs = _resolvedFirestore;
    var written = false;
    if (fs != null) {
      try {
        await fs.collection('finance_transfers').doc(id).set(
          {
            ...model.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        written = true;
      } catch (_) {}
    }
    if (!written) {
      final queue = syncQueue;
      if (queue != null) {
        await queue.enqueue(
          kind: 'firestore_set',
          entityId: id,
          payload: {
            'collection': 'finance_transfers',
            'docId': id,
            'fields': model.toMap(),
          },
        );
      }
    }
    return model;
  }

  Future<List<FinanceTransferEntity>> getShopTransfers(
      String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('finance_transfers')
            .where('shopId', isEqualTo: shopId)
            .get();
        for (final d in snap.docs) {
          final remote = FinanceTransferModel.fromMap(d.data());
          if (!_inMemory
              .any((m) => m.transferId == remote.transferId)) {
            _inMemory.add(remote);
          }
        }
      } catch (_) {}
    }
    final mine = _inMemory.where((t) => t.shopId == shopId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<List<FinanceTransferEntity>> getVehicleTransfers(
      String vehicleId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('finance_transfers')
            .where('vehicleId', isEqualTo: vehicleId)
            .get();
        for (final d in snap.docs) {
          final remote = FinanceTransferModel.fromMap(d.data());
          if (!_inMemory
              .any((m) => m.transferId == remote.transferId)) {
            _inMemory.add(remote);
          }
        }
      } catch (_) {}
    }
    final mine =
        _inMemory.where((t) => t.vehicleId == vehicleId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }
}
