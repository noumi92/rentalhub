import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Phase E (E3) — the app's push registration. After sign-in the
/// device's FCM token is stored on the user's document
/// (`fcm_token` + `fcm_token_updated_at`) so the admin's
/// `sendAnnouncement` Function can deliver broadcasts to the right
/// audience. It never blocks sign-in: every failure is swallowed.
///
/// Token refresh is listened to once (in main.dart) so a rotated
/// token is re-registered without another sign-in.
abstract final class PushTokenService {
  static bool _refreshListenerStarted = false;

  static Future<void> registerToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Push token registration skipped: $e');
    }
  }

  static void startRefreshListener() {
    if (_refreshListenerStarted) return;
    _refreshListenerStarted = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      registerToken();
    }, onError: (Object e) {
      debugPrint('Push token refresh failed: $e');
    });
  }
}
