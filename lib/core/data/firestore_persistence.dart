import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Phase B (B1): the Firestore offline baseline, pinned in one place.
///
/// The app used to rely on Firestore's offline cache implicitly —
/// nothing configured it and nothing verified it. This pins it:
/// persistence on, 100 MB cache, never disabled. Call
/// [configure] once at startup (main.dart, right after
/// `Firebase.initializeApp` and before anything touches Firestore —
/// the settings setter throws once the instance has been used).
///
/// A failed configuration never crashes startup: the app still runs
/// (Firestore's own default is persistence on), but the failure is
/// logged and [isConfigured] stays false so the baseline test can
/// catch a regression.
class FirestorePersistence {
  /// 100 MB offline cache (plan risk note: an unbounded cache can
  /// grow large on low-end phones).
  static const int cacheSizeBytes = 100 * 1024 * 1024;

  static bool _configured = false;

  /// True once the settings were applied in this process.
  static bool get isConfigured => _configured;

  static void configure({FirebaseFirestore? instance}) {
    if (_configured) return;
    try {
      final fs = instance ?? FirebaseFirestore.instance;
      fs.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: cacheSizeBytes,
      );
      _configured = true;
    } catch (e) {
      debugPrint('Firestore persistence notice: $e');
    }
  }

  /// Test-only: lets a test re-run [configure] in the same process.
  @visibleForTesting
  static void resetForTest() {
    _configured = false;
  }
}
