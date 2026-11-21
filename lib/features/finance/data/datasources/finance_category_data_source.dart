import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../domain/entities/finance_category_entity.dart';
import '../models/finance_category_model.dart';

/// Audit impl (O52): the `finance_categories` collection,
/// Firestore-first with an in-memory fallback. The lists the
/// ledger used to hardcode are the seed defaults, written on first
/// use per shop and kind — so existing entries keep their codes
/// and the add-entry sheet reads the same lists the owner edits.
class FinanceCategoryDataSource {
  final FirebaseFirestore? _firestore;
  final OfflineSyncQueue? syncQueue;
  final List<FinanceCategoryModel> _inMemory = [];
  var _idSeq = 0;

  FinanceCategoryDataSource({FirebaseFirestore? firestore, this.syncQueue})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// The hardcoded lists the ledger used before categories were
  /// manageable: income rent / advance / deposit / other, expense
  /// fuel / maintenance / wash / salary / partner share / deposit
  /// refund / other. 'advance' and 'wash' are new (O35/O36).
  static const Map<String, List<(String, String)>> defaultCategories = {
    'income': [
      ('rent', 'Rent'),
      ('advance', 'Advance'),
      ('deposit', 'Security'),
      ('other', 'Other'),
    ],
    'expense': [
      ('fuel', 'Fuel'),
      ('maintenance', 'Maintenance'),
      ('wash', 'Wash'),
      ('salary', 'Salary'),
      ('partner_share', 'Partner share'),
      ('deposit_refund', 'Security refund'),
      ('other', 'Other'),
    ],
  };

  static String slugify(String name) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'other' : slug;
  }

  Future<List<FinanceCategoryEntity>> getShopCategories(
    String shopId, {
    required String kind,
  }) async {
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        // Single-field query on shopId only (kind is filtered
        // below) so no composite Firestore index is needed.
        final snap = await fs
            .collection('finance_categories')
            .where('shopId', whereIn: ids)
            .get();
        for (final d in snap.docs) {
          final remote = FinanceCategoryModel.fromMap(d.data());
          if (!_inMemory.any((m) => m.categoryId == remote.categoryId)) {
            _inMemory.add(remote);
          }
        }
      } catch (_) {}
    }
    var mine = _inMemory
        .where((c) => ids.contains(c.shopId) && c.kind == kind)
        .toList();
    if (mine.isEmpty) {
      // First use: seed the defaults so the sheet keeps working
      // exactly as before until the owner edits the list.
      for (final (code, name) in defaultCategories[kind] ??
          const <(String, String)>[]) {
        mine.add(await _save(
          shopId: shopId,
          kind: kind,
          code: code,
          name: name,
        ));
      }
    }
    return mine;
  }

  Future<FinanceCategoryEntity> addCategory({
    required String shopId,
    required String kind,
    required String name,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Category name is required');
    if (kind != 'income' && kind != 'expense') {
      throw ArgumentError("kind must be 'income' or 'expense'");
    }
    final code = slugify(name);
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final existing = _inMemory.where(
        (c) => ids.contains(c.shopId) && c.kind == kind && c.code == code);
    if (existing.isNotEmpty) return existing.first;
    return _save(shopId: shopId, kind: kind, code: code, name: name.trim());
  }

  Future<FinanceCategoryModel> _save({
    required String shopId,
    required String kind,
    required String code,
    required String name,
  }) async {
    final canonical = await canonicalShopId(_resolvedFirestore, shopId);
    final id = 'CAT-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final model = FinanceCategoryModel(
      categoryId: id,
      shopId: canonical,
      kind: kind,
      code: code,
      name: name,
      createdAt: DateTime.now(),
    );
    _inMemory.add(model);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('finance_categories').doc(id).set(
          {
            ...model.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
    return model;
  }

  Future<void> renameCategory(String categoryId, String name) async {
    if (name.trim().isEmpty) throw ArgumentError('Category name is required');
    final index = _inMemory.indexWhere((c) => c.categoryId == categoryId);
    if (index < 0) return;
    _inMemory[index] = FinanceCategoryModel.fromEntity(
        _inMemory[index].copyWith(name: name.trim()));
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('finance_categories').doc(categoryId).set(
          {'name': name.trim()},
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    _inMemory.removeWhere((c) => c.categoryId == categoryId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('finance_categories').doc(categoryId).delete();
      } catch (_) {}
    }
  }
}
