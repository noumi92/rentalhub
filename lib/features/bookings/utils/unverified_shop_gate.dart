import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/data/repositories/platform_settings_repository.dart';

/// Customer-rework (Worker E) — whether a shop counts as verified,
/// from a raw `shops/{shopId}` document map.
///
/// A shop is verified when the admin approval wrote
/// `is_verified: true` or `verification_status` is 'approved'
/// (the value the admin shops data source writes on approval;
/// 'verified' is accepted too). A missing document, missing fields, or any
/// other value fails OPEN — the shop is treated as verified — so a
/// half-written shop document can never silently block bookings.
bool shopVerifiedFromData(Map<String, dynamic>? data) {
  if (data == null) return true;
  if (data['is_verified'] == true) return true;
  final status = data['verification_status'] as String?;
  if (status == 'approved' || status == 'verified') return true;
  if (data['is_verified'] == false) return false;
  if (status != null) return false;
  return true;
}

/// Reads `shops/{shopId}` and reports whether the shop is verified.
/// Never throws: any error (including no Firestore) returns true.
Future<bool> lookupShopVerified(
  String shopId, {
  FirebaseFirestore? firestore,
}) async {
  FirebaseFirestore? resolved = firestore;
  resolved ??= () {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }();
  if (resolved == null) return true;
  try {
    final doc = await resolved.collection('shops').doc(shopId).get();
    return shopVerifiedFromData(doc.data());
  } catch (_) {
    return true;
  }
}

/// The booking gate for unverified shops. A booking is allowed when
/// the shop is verified, or when the platform setting
/// `allowBookingsFromUnverifiedShops` is on (the default). Only an
/// unverified shop with that setting explicitly off is blocked.
/// [isBookingAllowed] never throws: any lookup error fails open.
class UnverifiedShopBookingGate {
  final PlatformSettingsRepository _settings;
  final Future<bool> Function(String shopId)? _shopVerifiedLookup;

  UnverifiedShopBookingGate({
    PlatformSettingsRepository? settings,
    Future<bool> Function(String shopId)? shopVerifiedLookup,
  })  : _settings = settings ?? const PlatformSettingsRepository(),
        _shopVerifiedLookup = shopVerifiedLookup;

  /// Resolves whether the shop is verified: an explicit flag wins,
  /// otherwise the `shops/{shopId}` document is read. Never throws.
  Future<bool> isShopVerified({
    required String shopId,
    bool? shopIsVerified,
  }) async {
    if (shopIsVerified != null) return shopIsVerified;
    return _lookupShopVerified(shopId);
  }

  Future<bool> isBookingAllowed({
    required String shopId,
    bool? shopIsVerified,
  }) async {
    final verified = await isShopVerified(
      shopId: shopId,
      shopIsVerified: shopIsVerified,
    );
    if (verified) return true;
    try {
      return await _settings.allowBookingsFromUnverifiedShops();
    } catch (_) {
      return true;
    }
  }

  Future<bool> _lookupShopVerified(String shopId) async {
    try {
      final lookup = _shopVerifiedLookup;
      if (lookup != null) return await lookup(shopId);
      return await lookupShopVerified(shopId);
    } catch (_) {
      return true;
    }
  }
}
