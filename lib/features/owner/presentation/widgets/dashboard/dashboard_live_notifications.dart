import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/utils/shop_id_resolution.dart';

/// Team B (UI/UX audit 2026-11-15, PW-19): the owner dashboard's
/// unread-notifications badge, live. The view used to load the count
/// once in `_loadDashboardData`, so the badge went stale while the
/// dashboard was open. This subscribes to the same
/// `notifications` query [NotificationDataSource.getShopNotifications]
/// reads (`shopId` in the candidate ids, both bare-UID and
/// `shop_<uid>` forms) and reports the unread count on every
/// emission — a notification arriving mid-morning updates the badge
/// without a refresh. Returns false when Firestore cannot be
/// resolved (tests / no Firebase); the caller keeps its one-time
/// count in that case.
class DashboardLiveNotifications {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// Starts the subscription (no-op when already live). Returns
  /// false when no Firestore is available.
  Future<bool> subscribe({
    required String shopId,
    required void Function(int unreadCount) onUnreadCount,
    FirebaseFirestore? firestore,
  }) async {
    if (_sub != null) return true;
    FirebaseFirestore? fs = firestore;
    fs ??= () {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {
        return null;
      }
    }();
    if (fs == null) return false;
    final ids = await candidateShopIds(fs, shopId);
    if (ids.isEmpty) {
      onUnreadCount(0);
      return true;
    }
    _sub = fs
        .collection('notifications')
        .where('shopId', whereIn: ids)
        .snapshots()
        .listen(
      (snap) {
        final unread =
            snap.docs.where((d) => d.data()['read'] != true).length;
        onUnreadCount(unread);
      },
      onError: (_) => _sub = null,
    );
    return true;
  }

  void dispose() => _sub?.cancel();
}
