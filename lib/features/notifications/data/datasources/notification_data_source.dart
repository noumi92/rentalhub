import 'dart:async';

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
  final StreamController<void> _changes = StreamController<void>.broadcast();
  var _idSeq = 0;

  NotificationDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  /// Broadcast stream fired whenever local/remote notification state
  /// changes (created, marked read, marked all read, or cache cleared).
  Stream<void> get changes => _changes.stream;

  void _notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Clears cached in-memory notifications (e.g. on sign-out / account switch).
  void clearCache() {
    _inMemory.clear();
    _notifyChanged();
  }

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
    String? customerId,
    String recipientRole = 'owner',
    required String title,
    required String body,
    required String type,
    String? bookingId,
    String? targetRoute,
  }) async {
    final canonical = shopId.isEmpty
        ? ''
        : await canonicalShopId(_resolvedFirestore, shopId);
    final id =
        'NTF-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final model = NotificationModel(
      notificationId: id,
      shopId: canonical,
      customerId: customerId,
      recipientRole: recipientRole,
      title: title,
      body: body,
      type: type,
      bookingId: bookingId,
      targetRoute: targetRoute,
      createdAt: DateTime.now(),
    );
    _inMemory.add(model);
    _notifyChanged();
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

  Future<NotificationEntity> createCustomerNotification({
    required String customerId,
    String shopId = '',
    required String title,
    required String body,
    required String type,
    String? bookingId,
    String? targetRoute,
  }) {
    return createNotification(
      shopId: shopId,
      customerId: customerId,
      recipientRole: 'customer',
      title: title,
      body: body,
      type: type,
      bookingId: bookingId,
      targetRoute: targetRoute,
    );
  }

  Future<List<NotificationEntity>> getShopNotifications(
      String shopId) async {
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null && ids.isNotEmpty) {
      try {
        final snap = await fs
            .collection('notifications')
            .where('shopId', whereIn: ids)
            .get();
        final remote = snap.docs
            .map((d) => NotificationModel.fromMap(d.data(), d.id))
            .toList();
        for (final n in remote) {
          final idx =
              _inMemory.indexWhere((m) => m.notificationId == n.notificationId);
          if (idx == -1) {
            _inMemory.add(n);
          } else {
            _inMemory[idx] = n;
          }
        }
      } catch (_) {}
    }
    final mine = _inMemory
        .where((n) => ids.contains(n.shopId) && n.recipientRole != 'customer')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<List<NotificationEntity>> getCustomerNotifications(
      String customerId) async {
    if (customerId.isEmpty) return const [];
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('notifications')
            .where('customerId', isEqualTo: customerId)
            .get();
        final remote = snap.docs
            .map((d) => NotificationModel.fromMap(d.data(), d.id))
            .toList();
        for (final n in remote) {
          final idx =
              _inMemory.indexWhere((m) => m.notificationId == n.notificationId);
          if (idx == -1) {
            _inMemory.add(n);
          } else {
            _inMemory[idx] = n;
          }
        }
      } catch (_) {}
    }
    final mine = _inMemory
        .where((n) =>
            n.customerId == customerId && n.recipientRole == 'customer')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<void> markRead(String notificationId) async {
    final idx =
        _inMemory.indexWhere((n) => n.notificationId == notificationId);
    final previous = idx != -1 ? _inMemory[idx] : null;
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
      } catch (_) {
        if (idx != -1 && previous != null) {
          _inMemory[idx] = previous;
        }
        rethrow;
      }
    }
    _notifyChanged();
  }

  Future<void> _markBatchRead(List<NotificationModel> unread) async {
    if (unread.isEmpty) return;
    final ids = unread.map((n) => n.notificationId).toSet();
    final previousById = <String, NotificationModel>{};
    for (var i = 0; i < _inMemory.length; i++) {
      if (ids.contains(_inMemory[i].notificationId)) {
        previousById[_inMemory[i].notificationId] = _inMemory[i];
        _inMemory[i] =
            NotificationModel.fromEntity(_inMemory[i].copyWith(read: true));
      }
    }
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final batch = fs.batch();
        for (final n in unread) {
          batch.update(
            fs.collection('notifications').doc(n.notificationId),
            {'read': true},
          );
        }
        await batch.commit();
      } catch (_) {
        for (var i = 0; i < _inMemory.length; i++) {
          final prev = previousById[_inMemory[i].notificationId];
          if (prev != null) _inMemory[i] = prev;
        }
        rethrow;
      }
    }
    _notifyChanged();
  }

  Future<void> markAllRead(String shopId) async {
    await getShopNotifications(shopId);
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final mine = _inMemory
        .where((n) =>
            ids.contains(n.shopId) &&
            n.recipientRole != 'customer' &&
            !n.read)
        .toList();
    await _markBatchRead(mine);
  }

  Future<void> markAllCustomerRead(String customerId) async {
    await getCustomerNotifications(customerId);
    final mine = _inMemory
        .where((n) =>
            n.customerId == customerId &&
            n.recipientRole == 'customer' &&
            !n.read)
        .toList();
    await _markBatchRead(mine);
  }
}
