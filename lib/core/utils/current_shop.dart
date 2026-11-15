import 'package:firebase_auth/firebase_auth.dart';

/// The signed-in owner's bare Firebase UID. This is NOT a shop
/// document id: shop documents are `shops/shop_<uid>` (field
/// `shop_id`, `owner_id` = the bare UID). Never use this value
/// directly as a `shops` doc id or as a `shopId` query/write value —
/// resolve it first with `candidateShopIds` (reads) or
/// `canonicalShopId` (writes) in `shop_id_resolution.dart`.
/// Falls back to the demo shop id when nobody is signed in or
/// Firebase is not initialised (tests, demo HUD), so callers never
/// crash on auth state.
String currentShopId() {
  try {
    return FirebaseAuth.instance.currentUser?.uid ?? 'shop-1';
  } catch (_) {
    return 'shop-1';
  }
}
