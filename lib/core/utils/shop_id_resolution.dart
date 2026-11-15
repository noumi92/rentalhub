import 'package:cloud_firestore/cloud_firestore.dart';

/// Shop-id resolution (2026-11-15) — mirrors the fleet pattern in
/// `lib/features/fleet/data/datasources/fleet_remote_data_source.dart`
/// (`_candidateShopIds` / `_canonicalShopId`, 2026-11-11 D12 fix).
///
/// The two id forms: a shop DOCUMENT id is `shop_<ownerUid>` (the
/// `shops` doc id and its `shop_id` field), while the owner app
/// historically passes the signed-in owner's bare UID
/// (`currentShopId()`). Customer-side writes (bookings, vehicles)
/// carry the document id; owner-side writes historically carried the
/// bare UID. Reads must therefore match both forms and writes must
/// carry the document id.
///
/// No static cache here on purpose: a lookup that runs before the
/// owner finishes onboarding would cache the bare UID as canonical
/// and never re-resolve. Callers that resolve repeatedly should hold
/// the result for their own lifetime if they need it.
Future<List<String>> candidateShopIds(
  FirebaseFirestore? fs,
  String shopId,
) async {
  final ids = <String>{shopId};
  if (fs != null) {
    try {
      final doc = await fs.collection('shops').doc(shopId).get();
      final ownerId = doc.data()?['owner_id'] as String?;
      if (ownerId != null && ownerId.isNotEmpty) ids.add(ownerId);
    } catch (_) {}
    try {
      final owned = await fs
          .collection('shops')
          .where('owner_id', isEqualTo: shopId)
          .limit(1)
          .get();
      if (owned.docs.isNotEmpty) ids.add(owned.docs.first.id);
    } catch (_) {}
  }
  return ids.toList();
}

/// The shop DOCUMENT id a new record for this shop must carry: the
/// doc id of the shop owned by this UID, or the argument itself when
/// no such shop exists (the legacy shop, whose doc id IS the UID).
Future<String> canonicalShopId(
  FirebaseFirestore? fs,
  String shopId,
) async {
  if (fs != null) {
    try {
      final owned = await fs
          .collection('shops')
          .where('owner_id', isEqualTo: shopId)
          .limit(1)
          .get();
      if (owned.docs.isNotEmpty) return owned.docs.first.id;
    } catch (_) {}
  }
  return shopId;
}
