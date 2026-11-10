import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/admin_permissions.dart';

/// Phase A (A1) — in-session TOTP gate for the admin panel, ported from
/// the old repo (noumi92/renthub Batch 14) and adapted to this repo.
///
/// After password sign-in, an admin whose users doc has totp_enabled
/// must also pass the TOTP step before any /admin screen (other than
/// /admin/login) may open. The admin login view marks the session
/// verified when verifyTotp succeeds; sign-out clears it. The flag lives
/// only in memory, so a page reload requires TOTP again — that is the
/// intended behaviour for two-factor authentication.
///
/// The router's redirect (AuthRouteGuard) adds this check after role
/// resolution:
///   if (location.startsWith('/admin') && location != '/admin/login') {
///     if (await AdminSession.adminNeedsTotp(user)) return '/admin/login';
///   }
///
/// Known limitation (documented, not hidden): the Firebase Auth session
/// itself exists after password sign-in, so TOTP is enforced at the
/// app's login/router gate, not in Firestore rules. A future hardening
/// step is a `totp_verified` custom claim checked by isAdmin() in the
/// rules (plan D3, resolved as a later item).
abstract final class AdminSession {
  static String? _totpVerifiedUid;
  static String? _cachedRole;
  static String? _cachedRoleUid;

  static void markTotpVerified(String uid) {
    _totpVerifiedUid = uid;
  }

  static void clear() {
    _totpVerifiedUid = null;
    _cachedRole = null;
    _cachedRoleUid = null;
  }

  /// The signed-in user's admin role, from their users doc
  /// (`admin_role`) with the custom claim as a fallback. Cached per
  /// uid for the session so the router redirect does not read Firestore
  /// on every navigation; cleared on sign-out.
  static Future<String?> resolveAdminRole(User user) async {
    if (_cachedRoleUid == user.uid) return _cachedRole;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final docRole = doc.data()?['admin_role'] as String?;
      if (docRole != null && AdminPermissions.allRoles.contains(docRole)) {
        _cachedRole = docRole;
        _cachedRoleUid = user.uid;
        return docRole;
      }
      final token = await user.getIdTokenResult();
      final claimRole = token.claims?['admin_role'] as String?;
      if (claimRole != null &&
          AdminPermissions.allRoles.contains(claimRole)) {
        _cachedRole = claimRole;
        _cachedRoleUid = user.uid;
        return claimRole;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool get isTotpVerifiedForCurrentUser {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      return uid != null && _totpVerifiedUid == uid;
    } catch (_) {
      return false;
    }
  }

  /// True when the signed-in admin has TOTP enabled on their user doc
  /// but has not completed the TOTP step in this session.
  static Future<bool> adminNeedsTotp(User user) async {
    if (_totpVerifiedUid == user.uid) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final totpEnabled = doc.data()?['totp_enabled'] as bool? ?? false;
      return totpEnabled;
    } catch (_) {
      return false;
    }
  }

  /// TEMPORARY (2026-11-10): the TOTP Cloud Functions are not deployed
  /// yet (billing postponed), so enrolment cannot run. True when the
  /// failure means the Functions backend is missing or unreachable —
  /// the admin login then falls back to password-only instead of
  /// stranding the admin on the TOTP step. REMOVE this once Functions
  /// are live: first login must enrol TOTP again.
  static bool isFunctionsUnavailable(Object e) {
    if (e is FirebaseException) {
      return e.code == 'not-found' || e.code == 'unavailable';
    }
    return e.toString().contains('Admin functions are unavailable');
  }
}
