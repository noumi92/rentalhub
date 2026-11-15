import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/shop_id_resolution.dart';

import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

/// Phase B (G2): the `notifications` collection, Firestore-first
/// with an in-memory fallback — the same pattern as the other
/// datasources. The shop reads its own notifications; the app
/// writes them when booking, payment and handover events happen.
class NotificationDataSource {
  final FirebaseFirestore? _firestore;
  final List<NotificationModel> _inMemory = [];
  var _idSeq = 0;

  NotificationDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<NotificationEntity> createNotification({
    required String shopId,
    required String title,
    required String body,
    required String type,
    String? bookingId,
  }) async {
    // Shop-id linking (2026-11-15): booking notifications arrive
    // with the booking's (canonical) shop id; canonicalize here so
    // every notification carries one id form.
    final canonical = await canonicalShopId(_resolvedFirestore, shopId);
    final id =
        'NTF-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final model = NotificationModel(
      notificationId: id,
      shopId: canonical,
      title: title,
      body: body,
      type: type,
      bookingId: bookingId,
      createdAt: DateTime.now(),
    );
    _inMemory.add(model);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs
            .collection('notifications')
            .doc(id)
            .set(model.toMap());
      } catch (_) {}
    }
    return model;
  }

  Future<List<NotificationEntity>> getShopNotifications(
      String shopId) async {
    // Shop-id linking (2026-11-15): notifications are written under
    // the booking's canonical shop id while the owner reads by bare
    // UID — the old `==` read missed them all. Match both forms.
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('notifications')
            .where('shopId', whereIn: ids)
            .get();
        final remote = snap.docs
            .map((d) => NotificationModel.fromMap(d.data()))
            .toList();
        for (final n in remote) {
          if (!_inMemory.any((m) => m.notificationId == n.notificationId)) {
            _inMemory.add(n);
          }
        }
      } catch (_) {}
    }
    final mine =
        _inMemory.where((n) => ids.contains(n.shopId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<void> markRead(String notificationId) async {
    final idx =
        _inMemory.indexWhere((n) => n.notificationId == notificationId);
    if (idx != -1) {
      _inMemory[idx] =
          NotificationModel.fromEntity(_inMemory[idx].copyWith(read: true));
    }
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs
            .collection('notifications')
            .doc(notificationId)
            .update({'read': true});
      } catch (_) {}
    }
  }

  Future<void> markAllRead(String shopId) async {
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final mine = _inMemory.where((n) => ids.contains(n.shopId)).toList();
    for (final n in mine) {
      await markRead(n.notificationId);
    }
  }
}
