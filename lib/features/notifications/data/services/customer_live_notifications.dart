import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Live unread-notification subscription for the signed-in customer,
/// mirroring [DashboardLiveNotifications] on the owner dashboard.
/// Also fires [onNewArrival] when a brand-new unread notification
/// arrives after the initial snapshot so the foreground UI can show
/// a non-intrusive toast/banner.
class CustomerLiveNotifications {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final Set<String> _seenUnreadIds = {};
  bool _initialLoaded = false;
  String? _activeCustomerId;

  Future<bool> subscribe({
    required String customerId,
    required void Function(int unreadCount) onUnreadCount,
    void Function(String title, String body, String? bookingId, String type)?
        onNewArrival,
    FirebaseFirestore? firestore,
  }) async {
    if (customerId.isEmpty) {
      dispose();
      onUnreadCount(0);
      return false;
    }
    if (_sub != null && _activeCustomerId == customerId) return true;
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
    _activeCustomerId = customerId;
    _sub = fs
        .collection('notifications')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .listen(
      (snap) {
        final unreadDocs = snap.docs
            .where((d) =>
                d.data()['read'] != true &&
                (d.data()['recipientRole'] ?? 'customer') == 'customer')
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
    _activeCustomerId = null;
    _initialLoaded = false;
    _seenUnreadIds.clear();
  }
}
