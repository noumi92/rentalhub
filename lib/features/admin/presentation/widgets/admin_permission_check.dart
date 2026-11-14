import 'package:flutter/widgets.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';

/// F-C1 — the one shared tap-time check for admin decision buttons.
///
/// Every admin decision entry point (views and sheets) calls
/// [check] before calling its data source, with the matrix
/// permission that decision needs:
///
/// - [AdminPermission.decideVendor] — shop approvals, suspend,
///   car review decisions
/// - [AdminPermission.manageBlacklist] — blacklist reports, appeal
///   decisions, watchlist, customer notes
/// - [AdminPermission.decideDispute] — dispute decisions
///   ([AdminPermission.manageDisputes] is view + triage; deciding
///   needs [AdminPermission.decideDispute])
/// - [AdminPermission.triageTicket] — ticket replies, notes,
///   escalate; [AdminPermission.resolveTicket] — closing a ticket
/// - [AdminPermission.managePlatform] — platform settings,
///   announcements, and reviews moderation (the matrix has no
///   dedicated reviews permission; moderation is a platform-level
///   decision, so super admin + operations only)
/// - [AdminPermission.manageTeam] — invites, TOTP resets, revokes
///
/// The check is fail-open while the role is still unknown (null):
/// the view renders its buttons as today and the data source —
/// which enforces the matrix for any signed-in caller
/// ([AdminSession.currentAdminCan]) — is the backstop that refuses
/// the write. Once the role is known and lacks the permission, the
/// tap is blocked here with an honest message instead of a
/// misleading "could not reach the server".
abstract final class AdminPermissionCheck {
  /// Returns the caller's role when the action may proceed, or null
  /// when it must not. A null role with [proceed] true means "role
  /// unknown — proceed, the data source decides"; pass that null
  /// role through to the data source so it resolves (and enforces)
  /// it itself.
  static Future<({bool proceed, String? role})> check(
    BuildContext context,
    AdminPermission permission,
  ) async {
    final role = await AdminSession.resolveCurrentAdminRole();
    if (role == null) return (proceed: true, role: null);
    if (AdminPermissions.can(role, permission)) {
      return (proceed: true, role: role);
    }
    if (context.mounted) {
      final l10n = AppLocalizations.of(context);
      AppFeedback.showError(
        context,
        l10n?.adminNotPermitted ??
            'Your admin role does not allow this action.',
      );
    }
    return (proceed: false, role: role);
  }
}
