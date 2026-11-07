import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';

import '../../domain/entities/cash_closing_entity.dart';
import '../models/cash_closing_model.dart';

/// Phase B (H5): the `cash_closings` collection, Firestore-first
/// with an in-memory fallback. One closing per shop per day — a
/// second close on the same day replaces the first, it never
/// creates a duplicate.
class CashClosingDataSource {
  final FirebaseFirestore? _firestore;
  final OfflineSyncQueue? syncQueue;
  final List<CashClosingModel> _inMemory = [];

  CashClosingDataSource({FirebaseFirestore? firestore, this.syncQueue})
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

  Future<CashClosingEntity> saveClosing({
    required String shopId,
    required DateTime date,
    required int openingCash,
    required int expectedCash,
    required int countedCash,
    String? note,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final id = 'CLS-$shopId-${day.millisecondsSinceEpoch}';
    final model = CashClosingModel(
      closingId: id,
      shopId: shopId,
      date: day,
      openingCash: openingCash,
      expectedCash: expectedCash,
      countedCash: countedCash,
      difference: countedCash - expectedCash,
      note: note,
      createdAt: DateTime.now(),
    );
    _inMemory.removeWhere((c) => c.closingId == id);
    _inMemory.add(model);
    final written = await _writeDoc('cash_closings', id, model.toMap());
    if (!written) await _queueDoc('cash_closings', id, model.toMap());
    return model;
  }

  Future<List<CashClosingEntity>> getShopClosings(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('cash_closings')
            .where('shopId', isEqualTo: shopId)
            .get();
        for (final d in snap.docs) {
          final remote = CashClosingModel.fromMap(d.data());
          if (!_inMemory.any((m) => m.closingId == remote.closingId)) {
            _inMemory.add(remote);
          }
        }
      } catch (_) {}
    }
    final mine = _inMemory.where((c) => c.shopId == shopId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return mine;
  }
}
