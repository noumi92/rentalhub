import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Admin-integration audit (2026-11-10) — the app-side half of the
/// admin announcement delivery.
///
/// The `sendAnnouncement` Cloud Function sends FCM with
/// `data: {announcementId}` and a notification payload. Before this,
/// nothing in the app listened for that payload: a background push
/// opened the app with no destination, and a foreground push was
/// never shown at all — the announcement existed only as a system
/// notification the user could dismiss.
///
/// This service listens for taps on announcement pushes
/// ([FirebaseMessaging.onMessageOpenedApp] + [getInitialMessage] for
/// a cold start from a terminated state) and emits the
/// `announcementId` on [announcementOpened]. It never throws and it
/// never navigates itself — navigation needs a router/view, which is
/// the remaining view-level step (there is no announcement detail
/// screen in the mobile app yet). Start it once from main.dart next
/// to [PushTokenService]; listeners subscribe to the broadcast
/// stream. Foreground display is intentionally out of scope here:
/// FirebaseMessaging does not show a banner for foreground messages
/// and the app has no local-notifications dependency.
class AnnouncementPushHandler {
  static StreamController<String>? _controller;
  static bool _started = false;

  /// Announcement ids from tapped pushes, in arrival order.
  static Stream<String> get announcementOpened {
    _controller ??= StreamController<String>.broadcast();
    return _controller!.stream;
  }

  static void start() {
    if (_started) return;
    _started = true;
    _controller ??= StreamController<String>.broadcast();
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final id = message.data['announcementId'];
        if (id is String && id.isNotEmpty) {
          _controller?.add(id);
        }
      }, onError: (Object e) {
        debugPrint('Announcement push listener failed: $e');
      });
      unawaited(FirebaseMessaging.instance.getInitialMessage().then(
        (message) {
          final id = message?.data['announcementId'];
          if (id is String && id.isNotEmpty) {
            _controller?.add(id);
          }
        },
        onError: (Object e) {
          debugPrint('Announcement initial message failed: $e');
        },
      ));
    } catch (e) {
      debugPrint('Announcement push handler skipped: $e');
    }
  }
}
