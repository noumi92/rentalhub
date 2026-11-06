import 'package:firebase_auth/firebase_auth.dart';

/// The signed-in owner's uid is the shop id (the onboarding flow writes
/// the shop document under the owner's uid). Falls back to the demo shop
/// id when nobody is signed in or Firebase is not initialised (tests,
/// demo HUD), so callers never crash on auth state.
String currentShopId() {
  try {
    return FirebaseAuth.instance.currentUser?.uid ?? 'shop-1';
  } catch (_) {
    return 'shop-1';
  }
}
