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
  final Set<String> _seenUnreadIds = {};
  bool _initialLoaded = false;
  String? _activeShopId;

  /// Starts the subscription (no-op when already live for the same shop).
  /// Returns false when no Firestore is available.
  Future<bool> subscribe({
    required String shopId,
    required void Function(int unreadCount) onUnreadCount,
    void Function(String title, String body, String? bookingId, String type)?
        onNewArrival,
    FirebaseFirestore? firestore,
  }) async {
    if (_sub != null && _activeShopId == shopId) return true;
    dispose();
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
    _activeShopId = shopId;
    _sub = fs
        .collection('notifications')
        .where('shopId', whereIn: ids)
        .snapshots()
        .listen(
      (snap) {
        final unreadDocs = snap.docs
            .where((d) =>
                d.data()['read'] != true &&
                d.data()['recipientRole'] != 'customer')
            .toList();
        onUnreadCount(unreadDocs.length);
        if (_initialLoaded && onNewArrival != null) {
          for (final d in unreadDocs) {
            if (_seenUnreadIds.add(d.id)) {
              final data = d.data();
              onNewArrival(
                (data['title'] as String?) ?? '',
                (data['body'] as String?) ?? '',
                data['bookingId'] as String?,
                (data['type'] as String?) ?? 'general',
              );
            }
          }
        } else {
          for (final d in unreadDocs) {
            _seenUnreadIds.add(d.id);
          }
          _initialLoaded = true;
        }
      },
      onError: (_) => dispose(),
    );
    return true;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _activeShopId = null;
    _initialLoaded = false;
    _seenUnreadIds.clear();
  }
}
