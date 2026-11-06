import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/cash_closing_entity.dart';
import '../models/cash_closing_model.dart';

/// Phase B (H5): the `cash_closings` collection, Firestore-first
/// with an in-memory fallback. One closing per shop per day — a
/// second close on the same day replaces the first, it never
/// creates a duplicate.
class CashClosingDataSource {
  final FirebaseFirestore? _firestore;
  final List<CashClosingModel> _inMemory = [];

  CashClosingDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
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
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('cash_closings').doc(id).set(model.toMap());
      } catch (_) {}
    }
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
