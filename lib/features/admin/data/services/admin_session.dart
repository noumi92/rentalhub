import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/admin_permissions.dart';
import 'admin_audit_service.dart';

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

  /// F-m9 — how long a resolved admin role is trusted before the
  /// guard and the decision methods re-read the users doc. A role
  /// revoked in the team view used to stay live until the admin
  /// reloaded or signed out, because the role was cached for the
  /// whole session. Five minutes bounds that window; a revocation
  /// also clears the cache entry for the revoked uid immediately
  /// (see [clearCachedRole]).
  static const _roleCacheTtl = Duration(minutes: 5);
  static DateTime? _cachedRoleAt;

  /// A Firestore read for the router guard must never hang the route:
  /// after a tab is backgrounded the connection can go stale and a
  /// server read may never answer, leaving the splash screen stuck
  /// (go_router holds the current route while the redirect is
  /// pending). Five seconds is ample for a healthy read; beyond that
  /// the guard sends the admin to the login step, which re-resolves
  /// the profile once the connection recovers.
  static const _guardReadTimeout = Duration(seconds: 5);

  /// Runs a guard read with the guard timeout: a read that never
  /// answers (or throws) resolves to null instead of hanging the
  /// route. Public so the bound itself is covered by tests.
  static Future<T?> guardRead<T>(Future<T> Function() read) async {
    try {
      return await read().timeout(_guardReadTimeout);
    } catch (_) {
      return null;
    }
  }

  static void markTotpVerified(String uid) {
    _totpVerifiedUid = uid;
  }

  static void clear() {
    _totpVerifiedUid = null;
    _cachedRole = null;
    _cachedRoleUid = null;
    _cachedRoleAt = null;
  }

  /// F-m9 — drop the cached role for one uid, so a revocation made
  /// in the team view takes effect without waiting for the TTL.
  /// The cache lives in this browser tab only, so this clears the
  /// revoker's copy; the revoked admin's own live session re-reads
  /// the role once its TTL expires (see [_roleCacheTtl]).
  static void clearCachedRole(String uid) {
    if (_cachedRoleUid == uid) {
      _cachedRole = null;
      _cachedRoleUid = null;
      _cachedRoleAt = null;
    }
  }

  /// The signed-in user's admin role, from their users doc
  /// (`admin_role`) with the custom claim as a fallback. Cached per
  /// uid for [_roleCacheTtl] so the router redirect does not read
  /// Firestore on every navigation; cleared on sign-out, on role
  /// revocation ([clearCachedRole]), or with [forceRefresh].
  static Future<String?> resolveAdminRole(User user,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedRoleUid == user.uid &&
        _cachedRole != null &&
        _cachedRoleAt != null &&
        DateTime.now().difference(_cachedRoleAt!) < _roleCacheTtl) {
      return _cachedRole;
    }
    try {
      final doc = await guardRead(() => FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get());
      if (doc == null) return null;
      final docRole = doc.data()?['admin_role'] as String?;
      if (docRole != null && AdminPermissions.allRoles.contains(docRole)) {
        _cachedRole = docRole;
        _cachedRoleUid = user.uid;
        _cachedRoleAt = DateTime.now();
        return docRole;
      }
      final token = await user.getIdTokenResult();
      final claimRole = token.claims?['admin_role'] as String?;
      if (claimRole != null &&
          AdminPermissions.allRoles.contains(claimRole)) {
        _cachedRole = claimRole;
        _cachedRoleUid = user.uid;
        _cachedRoleAt = DateTime.now();
        return claimRole;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// The signed-in admin's role, or null when there is no signed-in
  /// user or the role cannot be read. Never throws. Views treat null
  /// as "unknown" (they render as today); [currentAdminCan] treats
  /// it as "no session to gate" when nobody is signed in, and as
  /// "not permitted" when a signed-in user's role cannot be read.
  static Future<String?> resolveCurrentAdminRole() async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
    if (user == null) return null;
    return resolveAdminRole(user);
  }

  /// F-C1 — the data-source backstop for the permission matrix:
  /// true only when the caller's role holds [permission]. Pass the
  /// role the view already resolved when one is known; otherwise the
  /// current session's role is resolved (cached, TTL-bounded).
  ///
  /// An explicitly passed role is judged strictly. With no role
  /// passed: a signed-in user whose role cannot be read is refused
  /// (fail closed — an outage must not become a privilege), while
  /// no signed-in user at all proceeds — there is no admin identity
  /// to gate (the offline / test path, where the data sources fall
  /// back to in-memory results), and the write attempt itself is
  /// still judged by the Firestore rules, which require an
  /// authenticated admin. A direct call by a signed-in support
  /// admin is refused either way, because their role resolves.
  static Future<bool> currentAdminCan(AdminPermission permission,
      {String? adminRole}) async {
    if (adminRole != null) {
      return AdminPermissions.can(adminRole, permission);
    }
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return true;
    }
    if (user == null) return true;
    final role = await resolveAdminRole(user);
    return AdminPermissions.can(role, permission);
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
    final doc = await guardRead(() => FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get());
    // Unreadable (timed out or errored): send the admin to the login
    // step rather than hanging the route or silently skipping TOTP.
    if (doc == null) return true;
    return doc.data()?['totp_enabled'] as bool? ?? false;
  }

  /// TEMPORARY (2026-11-10): the TOTP Cloud Functions are not deployed
  /// yet (billing postponed), so enrolment cannot run. True when the
  /// failure means the Functions backend is missing or unreachable —
  /// the admin login then falls back to password-only instead of
  /// stranding the admin on the TOTP step. REMOVE this once Functions
  /// are live: first login must enrol TOTP again.
  ///
  /// 'internal' is what the empty endpoint actually returns (2026-11-14):
  /// calling a callable that was never deployed answers with a non-JSON
  /// 404, which the SDK reports as firebase_functions/internal — so the
  /// first sign-in showed the TOTP step with an "Internal" error instead
  /// of falling back.
  static bool isFunctionsUnavailable(Object e) {
    if (e is FirebaseException) {
      return e.code == 'not-found' ||
          e.code == 'unavailable' ||
          e.code == 'internal';
    }
    return e.toString().contains('Admin functions are unavailable');
  }

  /// F-M4 — TEMPORARY (same posture as the enrolment fallback, same
  /// REMOVE-once-live marker): when an enrolled admin's `verifyTotp`
  /// call fails only because the Functions backend is missing, fall
  /// back to password-only for this session instead of locking the
  /// admin out. The in-memory verified flag is set so the router
  /// guard does not bounce the admin straight back to the TOTP step,
  /// and an audit entry records that the fallback was used. Returns
  /// true when the fallback applied; any other failure returns false
  /// and must still show its error. REMOVE once the TOTP Functions
  /// are live: first login must verify TOTP again.
  static Future<bool> tryPasswordOnlyFallback(Object e) async {
    if (!isFunctionsUnavailable(e)) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    markTotpVerified(user.uid);
    await AdminAuditService.logAction(
      action: 'admin_totp_verify_fallback',
      targetType: 'admin',
      targetId: user.uid,
      detail:
          'TEMPORARY password-only sign-in: verifyTotp unavailable (Functions not deployed).',
    );
    return true;
  }
}
