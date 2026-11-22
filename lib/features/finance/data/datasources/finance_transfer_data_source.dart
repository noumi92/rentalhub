import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/utils/shop_id_resolution.dart';
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

  /// Financial audit (2026-11-20): an explicit [transferId] makes
  /// a posting idempotent — the same cash event replayed (retry,
  /// offline-queue replay, a second call site) merge-sets the same
  /// Firestore doc instead of writing a second ledger line. Null
  /// keeps the old generated id for manual entries.
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
    String? transferId,
  }) async {
    if (kind != 'income' && kind != 'expense') {
      throw ArgumentError("kind must be 'income' or 'expense'");
    }
    if (amountPkr <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }
    final id = transferId ??
        'TRF-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final canonical = await canonicalShopId(_resolvedFirestore, shopId);
    final model = FinanceTransferModel(
      transferId: id,
      shopId: canonical,
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
    // Financial audit (2026-11-20): a re-post under an explicit
    // id (e.g. a partial advance followed by the full verification)
    // replaces the in-memory entry — the Firestore merge-set
    // already overwrites the doc, so without this the local list
    // would hold the same transfer twice.
    _inMemory.removeWhere((m) => m.transferId == id);
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

  /// Financial audit (2026-11-20): whether a deterministic ledger
  /// id (see [BookingLedgerService]) was already posted — the
  /// in-memory list first, then the Firestore doc. False on any
  /// read failure: the caller re-posts with the same id and the
  /// merge-set still lands exactly once.
  Future<bool> transferExists(String transferId) async {
    if (_inMemory.any((m) => m.transferId == transferId)) return true;
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      final doc =
          await fs.collection('finance_transfers').doc(transferId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<List<FinanceTransferEntity>> getShopTransfers(
      String shopId) async {
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('finance_transfers')
            .where('shopId', whereIn: ids)
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
    final mine = _inMemory.where((t) => ids.contains(t.shopId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<List<FinanceTransferEntity>> getVehicleTransfers(
    String vehicleId, {
    String? shopId,
  }) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        Query<Map<String, dynamic>> query = fs
            .collection('finance_transfers')
            .where('vehicleId', isEqualTo: vehicleId);
        if (shopId != null && shopId.isNotEmpty) {
          query = query.where('shopId', isEqualTo: shopId);
        }
        final snap = await query.get();
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
