import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../domain/entities/staff_entity.dart';
import '../models/staff_model.dart';

/// Audit impl (O51): the `staff` collection, Firestore-first with
/// an in-memory fallback — the same pattern as the finance data
/// sources. The collection and field names are a cross-worker
/// contract (worker E reads this collection): do not rename them.
class StaffDataSource {
  final FirebaseFirestore? _firestore;
  final OfflineSyncQueue? syncQueue;
  final List<StaffModel> _inMemory = [];
  var _idSeq = 0;

  StaffDataSource({FirebaseFirestore? firestore, this.syncQueue})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<StaffEntity> addStaff({
    required String shopId,
    required String name,
    required String role,
    String phone = '',
    bool viewBookings = true,
    bool addCars = false,
    bool manageFinance = false,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Staff name is required');
    if (role.trim().isEmpty) throw ArgumentError('Staff role is required');
    final canonical = await canonicalShopId(_resolvedFirestore, shopId);
    final id = 'STF-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final model = StaffModel(
      staffId: id,
      shopId: canonical,
      name: name.trim(),
      role: role.trim(),
      phone: phone.trim(),
      viewBookings: viewBookings,
      addCars: addCars,
      manageFinance: manageFinance,
      createdAt: DateTime.now(),
    );
    _inMemory.add(model);
    final fs = _resolvedFirestore;
    var written = false;
    if (fs != null) {
      try {
        await fs.collection('staff').doc(id).set(
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
    if (!written && syncQueue != null) {
      await syncQueue!.enqueue(
        kind: 'firestore_set',
        entityId: id,
        payload: {
          'collection': 'staff',
          'docId': id,
          'fields': model.toMap(),
        },
      );
    }
    return model;
  }

  Future<List<StaffEntity>> getShopStaff(String shopId) async {
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('staff')
            .where('shopId', whereIn: ids)
            .get();
        for (final d in snap.docs) {
          final remote = StaffModel.fromMap(d.data());
          if (!_inMemory.any((m) => m.staffId == remote.staffId)) {
            _inMemory.add(remote);
          }
        }
      } catch (_) {}
    }
    final mine = _inMemory.where((s) => ids.contains(s.shopId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<void> updatePermissions({
    required String staffId,
    required bool viewBookings,
    required bool addCars,
    required bool manageFinance,
  }) async {
    final index = _inMemory.indexWhere((s) => s.staffId == staffId);
    if (index < 0) return;
    final updated = _inMemory[index].copyWith(
      viewBookings: viewBookings,
      addCars: addCars,
      manageFinance: manageFinance,
    );
    _inMemory[index] = StaffModel.fromEntity(updated);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('staff').doc(staffId).set(
          {'permissions': StaffModel.fromEntity(updated).toMap()['permissions']},
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  Future<void> deleteStaff(String staffId) async {
    _inMemory.removeWhere((s) => s.staffId == staffId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('staff').doc(staffId).delete();
      } catch (_) {}
    }
  }
}
