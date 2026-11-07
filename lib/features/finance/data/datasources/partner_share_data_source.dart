import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';

import '../../domain/entities/partner_share_entity.dart';
import '../models/partner_share_model.dart';

/// Phase B (H4): the `partner_shares` collection, Firestore-first
/// with an in-memory fallback.
class PartnerShareDataSource {
  final FirebaseFirestore? _firestore;
  final OfflineSyncQueue? syncQueue;
  final List<PartnerShareModel> _inMemory = [];
  var _idSeq = 0;

  PartnerShareDataSource({FirebaseFirestore? firestore, this.syncQueue})
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

  Future<PartnerShareEntity> savePartner({
    required String shopId,
    required String partnerName,
    required int sharePercent,
  }) async {
    if (partnerName.trim().isEmpty) {
      throw ArgumentError('Partner name is required');
    }
    if (sharePercent < 0 || sharePercent > 100) {
      throw ArgumentError('Share must be between 0 and 100 percent');
    }
    final id =
        'SHR-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final model = PartnerShareModel(
      shareId: id,
      shopId: shopId,
      partnerName: partnerName.trim(),
      sharePercent: sharePercent,
      createdAt: DateTime.now(),
    );
    _inMemory.add(model);
    final written = await _writeDoc('partner_shares', id, model.toMap());
    if (!written) await _queueDoc('partner_shares', id, model.toMap());
    return model;
  }

  Future<List<PartnerShareEntity>> getShopPartners(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('partner_shares')
            .where('shopId', isEqualTo: shopId)
            .get();
        for (final d in snap.docs) {
          final remote = PartnerShareModel.fromMap(d.data());
          if (!_inMemory.any((m) => m.shareId == remote.shareId)) {
            _inMemory.add(remote);
          }
        }
      } catch (_) {}
    }
    final mine = _inMemory.where((p) => p.shopId == shopId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }
}
