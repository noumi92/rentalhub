import 'package:firebase_auth/firebase_auth.dart';

/// Who is signed in, for UI code that must not load another user's data.
///
/// Production reads `FirebaseAuth.instance.currentUser`. Widget tests
/// cannot sign a user in — `FirebaseAuth` needs a real Firebase app,
/// which the test binding never initialises — so a test may set
/// [override] to stand in for a signed-in user. Production never sets
/// it; tests clear it in `tearDown`. Same pattern as
/// `AppPlatform.isWebOverride`.
///
/// Audit CU-m3 / SH-C1 (2026-11-13): signed-out reads/writes used to
/// fall back to shared demo ids. That fallback is gone everywhere —
/// a signed-out caller gets an explicit error state and nothing is
/// filed under a fake identity. This helper is how tests exercise
/// the signed-in path without reintroducing a fallback in
/// production code.
class SignedInUser {
  /// Test-only stand-in for the signed-in user. Null in production.
  static SignedInUserData? override;

  /// The signed-in uid, or '' when nobody is signed in — never a
  /// demo fallback.
  static String uid() {
    final o = override;
    if (o != null) return o.uid;
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// The signed-in user (uid + profile fields), or null when nobody
  /// is signed in.
  static SignedInUserData? current() {
    final o = override;
    if (o != null) return o;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return SignedInUserData(
        uid: user.uid,
        displayName: user.displayName,
        phoneNumber: user.phoneNumber,
        email: user.email,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The signed-in user's identity, as the UI needs it.
class SignedInUserData {
  const SignedInUserData({
    required this.uid,
    this.displayName,
    this.phoneNumber,
    this.email,
  });

  final String uid;
  final String? displayName;
  final String? phoneNumber;
  final String? email;
}
