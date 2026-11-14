import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer-rework (Worker E) — the customer-side read contract for
/// the two admin toggles on `platform_settings/global`.
///
/// Worker B's Shops view reads [displayUnverifiedShops] and the
/// booking flow reads [allowBookingsFromUnverifiedShops]. Both
/// default to true: a missing document, a missing field, a
/// non-boolean value, or any error (including no Firestore at all)
/// never hides a shop or blocks a booking. The methods never throw.
class PlatformSettingsRepository {
  final FirebaseFirestore? _firestore;

  const PlatformSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _readGlobal() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore
          .collection('platform_settings')
          .doc('global')
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// True when the platform is in maintenance mode
  /// (`platform_settings/global.maintenance_mode`). Defaults to
  /// false when the document or the field is missing, or on any
  /// error — a failed read never locks users out of the app; only
  /// an explicit `true` shows the maintenance notice (splash gate).
  /// Admin audit (2026-11-14, F-M13): the toggle used to flip a
  /// flag nothing read. The splash screen reads this now.
  Future<bool> maintenanceMode() async {
    try {
      return maintenanceModeFromData(await _readGlobal());
    } catch (_) {
      return false;
    }
  }

  /// Pure default-false parsing of the `maintenance_mode` field, so
  /// the behaviour is unit-testable without Firestore. Only an
  /// explicit `true` puts the platform in maintenance mode.
  static bool maintenanceModeFromData(Map<String, dynamic>? data) {
    final value = data?['maintenance_mode'];
    if (value is bool) return value;
    return false;
  }

  /// True when unverified shops may be shown in discovery. Defaults
  /// to true when the document or the `displayUnverifiedShops`
  /// field is missing, or on any error.
  Future<bool> displayUnverifiedShops() async {
    try {
      return displayFromData(await _readGlobal());
    } catch (_) {
      return true;
    }
  }

  /// True when customers may book from unverified shops. Defaults
  /// to true when the document or the `allowBookingsFromUnverifiedShops`
  /// field is missing, or on any error.
  Future<bool> allowBookingsFromUnverifiedShops() async {
    try {
      return allowBookingsFromData(await _readGlobal());
    } catch (_) {
      return true;
    }
  }

  /// Pure default-true parsing of the `displayUnverifiedShops`
  /// field, so the missing-field behaviour is unit-testable without
  /// Firestore. Only an explicit `false` hides unverified shops.
  static bool displayFromData(Map<String, dynamic>? data) {
    final value = data?['displayUnverifiedShops'];
    if (value is bool) return value;
    return true;
  }

  /// Pure default-true parsing of the `allowBookingsFromUnverifiedShops`
  /// field. Only an explicit `false` blocks unverified bookings.
  static bool allowBookingsFromData(Map<String, dynamic>? data) {
    final value = data?['allowBookingsFromUnverifiedShops'];
    if (value is bool) return value;
    return true;
  }
}
