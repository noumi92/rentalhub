import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/services/admin_audit_service.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_invite_form.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_team_invites_section.dart';
import '../widgets/admin_team_members_section.dart';

/// Phase A (A4) — the admin team screen: who holds an admin role, who
/// still has two-factor authentication off, and (super admin only) the
/// invite form, TOTP resets and role revocations. Invites expire after
/// 48 hours; the grant happens on the accept screen through
/// setAdminRole, once the invitee's account exists. The invite form
/// owns the invite flow; this view loads, prunes, reminds, confirms.
class AdminTeamView extends StatefulWidget {
  /// The signed-in admin's role. The router leaves it null and the
  /// view resolves it from the signed-in user; tests pass it directly.
  final String? adminRole;

  const AdminTeamView({super.key, this.adminRole});

  @override
  State<AdminTeamView> createState() => _AdminTeamViewState();
}

class _AdminTeamViewState extends State<AdminTeamView> {
  List<AdminTeamMember> _members = [];
  List<AdminInvite> _invites = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isWorking = false;
  String? _role;

  // F-m4: the check used to be a raw `role == 'super_admin'` comparison, bypassing the matrix — it now goes through it.
  bool get _canManage =>
      AdminPermissions.can(_role, AdminPermission.manageTeam);

  @override
  void initState() {
    super.initState();
    _role = widget.adminRole;
    _load();
  }

  Future<void> _load() async {
    // Resolve the signed-in admin's role once (cached 5 min).
    _role ??= await AdminSession.resolveCurrentAdminRole();
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final ds = sl<AdminRemoteDataSource>();
      // F-m4: expired invites lingered forever — prune them first
      // (best effort; the scheduled function does the same nightly,
      // and a prune failure must never hide the team list).
      try {
        await ds.pruneExpiredInvites();
      } catch (_) {}
      final members = await ds.getTeamMembers();
      final invites = await ds.getInvites();
      if (mounted) {
        setState(() {
          _members = members;
          _invites = invites;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// F-m4: remind every 2FA-off member — one
  /// `admin_totp_reminders/{uid}` write each, reported honestly;
  /// the reminded admin sees the banner at their next sign-in.
  Future<void> _remindAll2fa() async {
    final off = _members.where((m) => !m.totpEnabled).toList();
    if (off.isEmpty || _isWorking) return;
    setState(() => _isWorking = true);
    var sent = 0;
    for (final m in off) {
      try {
        await sl<AdminRemoteDataSource>()
            .recordTotpReminder(m.uid, callerRole: _role);
        await AdminAuditService.logAction(
          action: 'totp_reminder_sent',
          targetType: 'admin',
          targetId: m.uid,
          detail: '2FA reminder sent to ${m.email}.',
        );
        sent++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _isWorking = false);
    final l10n = AppLocalizations.of(context);
    if (sent == off.length) {
      AppFeedback.showSuccess(context,
          l10n?.admin2_teamTotpReminderSent ?? '2FA reminders sent.');
    } else {
      AppFeedback.showError(context,
          l10n?.admin2_teamTotpReminderFailed ??
              'Could not send the reminders.');
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String body,
    required Future<void> Function() run,
  }) async {
    if (!await showAdminConfirmDialog(context, title: title, body: body)) return;
    setState(() => _isWorking = true);
    try {
      await run();
      await _load();
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
            context,
            AppLocalizations.of(context)?.admin2_teamActionFailed ??
                'Could not complete that action.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    final l10n = AppLocalizations.of(context);
    return AdminShell(
      activeRoute: RouteNames.adminTeam,
      title: l10n?.admin2_navAdminTeam ?? 'Admin Team',
      subtitle: l10n?.admin2_teamSubtitle ??
          'Who can run the platform, and with what role',
      onRefresh: _load,
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n?.admin2_teamLoadFailed ??
                      'Could not load the admin team.',
                  onRetry: _load,
                )
              : ListView(
              padding: EdgeInsets.all(compact ? 16 : 24),
              children: [
                if (!_canManage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      l10n?.admin2_teamViewOnly ??
                          'Only a super admin can invite, reset two-factor authentication, or revoke a role. You can view the team.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                AdminTeamMembersSection(
                  members: _members,
                  canManage: _canManage,
                  isWorking: _isWorking,
                  onRemindAll2fa: _canManage ? _remindAll2fa : null,
                  onResetTotp: (m) => _confirmAction(
                    title: l10n?.admin2_teamResetTotpTitle ??
                        'Reset two-factor authentication?',
                    body: l10n?.admin2_teamResetTotpBody(m.email) ??
                        '${m.email} will have to enrol TOTP again on their next login.',
                    run: () async {
                      await sl<AdminRemoteDataSource>()
                          .resetTotp(m.uid, callerRole: _role);
                      await AdminAuditService.logAction(
                        action: 'totp_reset',
                        targetType: 'admin',
                        targetId: m.uid,
                        detail: l10n?.admin2_teamTotpResetLog(m.email) ??
                            'TOTP reset for ${m.email}.',
                      );
                    },
                  ),
                  onRevoke: (m) => _confirmAction(
                    title: l10n?.admin2_teamRevokeTitle ??
                        'Revoke this admin role?',
                    body: l10n?.admin2_teamRevokeBody(m.email) ??
                        '${m.email} will lose admin access and become a customer account.',
                    run: () async {
                      await sl<AdminRemoteDataSource>()
                          .setAdminRole(uid: m.uid, adminRole: null, callerRole: _role);
                      // F-m9: drop this tab's cached copy of the
                      // revoked uid's role now (their own session
                      // re-reads it once its 5-minute TTL expires).
                      AdminSession.clearCachedRole(m.uid);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                AdminTeamInvitesSection(
                  invites: _invites,
                  canManage: _canManage,
                  onAccept: (i) => context.go(
                      '${RouteNames.adminInviteAccept}?email=${Uri.encodeComponent(i.email)}&role=${Uri.encodeComponent(i.adminRole)}'),
                  onWithdraw: (i) => _confirmAction(
                    title: l10n?.admin2_teamWithdrawTitle ??
                        'Withdraw this invite?',
                    body: l10n?.admin2_teamWithdrawBody(i.email) ??
                        '${i.email} will no longer be able to accept it.',
                    run: () async {
                      await sl<AdminRemoteDataSource>()
                          .revokeInvite(i.id, callerRole: _role);
                      await AdminAuditService.logAction(
                        action: 'admin_invite_revoked',
                        targetType: 'admin_invite',
                        targetId: i.email,
                        detail: l10n?.admin2_teamInviteWithdrawnLog(i.email) ??
                            'Invite withdrawn for ${i.email}.',
                      );
                    },
                  ),
                ),
                if (_canManage) ...[
                  const SizedBox(height: 24),
                  Text(l10n?.admin2_teamInviteButton ?? 'Invite an admin',
                      style: const TextStyle(
                          fontSize: 15,
                          )),
                  const SizedBox(height: 10),
                  AdminInviteForm(
                    callerRole: _role,
                    onInvited: _load,
                  ),
                ],
              ],
            ),
    );
  }
}
