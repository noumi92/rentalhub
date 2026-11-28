import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_team_invites_tab.dart';
import '../widgets/admin_team_members_tab.dart';
import '../widgets/admin_team_security_tab.dart';

/// Admin team roles, invites, and 2FA security management.
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
      // Phase 3 (3.5a): no client-side prune on load — expired
      // invites are pruned by the scheduled
      // `pruneExpiredInvites` Cloud Function (nightly), so a team
      // load no longer performs an unaudited delete. Note: the
      // Functions deploy is still blocked on billing, so until it
      // lands expired invites linger in the list (shown as expired).
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
        await sl<AdminRemoteDataSource>().recordTotpReminder(m.uid, callerRole: _role);
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
        AppFeedback.showError(context, AppLocalizations.of(context)?.admin2_teamActionFailed ?? 'Could not complete that action.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _resetTotp(AdminTeamMember m) {
    final l10n = AppLocalizations.of(context);
    _confirmAction(
      title: l10n?.admin2_teamResetTotpTitle ?? 'Reset two-factor authentication?',
      body: l10n?.admin2_teamResetTotpBody(m.email) ?? '${m.email} will have to enrol TOTP again on their next login.',
      run: () async {
        await sl<AdminRemoteDataSource>().resetTotp(m.uid, callerRole: _role);
      },
    );
  }

  void _revoke(AdminTeamMember m) {
    final l10n = AppLocalizations.of(context);
    _confirmAction(
      title: l10n?.admin2_teamRevokeTitle ?? 'Revoke this admin role?',
      body: l10n?.admin2_teamRevokeBody(m.email) ?? '${m.email} will lose admin access and become a customer account.',
      run: () async {
        await sl<AdminRemoteDataSource>().setAdminRole(uid: m.uid, adminRole: null, callerRole: _role);
        // F-m9: drop this tab's cached copy of the revoked uid's role now (their own session re-reads it once its 5-minute TTL expires).
        AdminSession.clearCachedRole(m.uid);
      },
    );
  }

  void _withdrawInvite(AdminInvite i) {
    final l10n = AppLocalizations.of(context);
    _confirmAction(
      title: l10n?.admin2_teamWithdrawTitle ?? 'Withdraw this invite?',
      body: l10n?.admin2_teamWithdrawBody(i.email) ?? '${i.email} will no longer be able to accept it.',
      run: () async {
        await sl<AdminRemoteDataSource>().revokeInvite(i.id, callerRole: _role);
      },
    );
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
      subTabs: AdminSectionTabs.platformAndSystem(
        context,
        activeRoute: RouteNames.adminTeam,
        canDownloadApk:
            AdminPermissions.can(_role, AdminPermission.downloadApk),
      ),
      onRefresh: _load,
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n?.admin2_teamLoadFailed ??
                      'Could not load the admin team.',
                  onRetry: _load,
                )
              : DefaultTabController(
                  length: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_canManage)
                        Padding(
                          padding: EdgeInsets.fromLTRB(compact ? 16 : 24, compact ? 16 : 24, compact ? 16 : 24, 0),
                          child: Text(
                            l10n?.admin2_teamViewOnly ?? 'Only a super admin can invite, reset two-factor authentication, or revoke a role. You can view the team.',
                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      TabBar(
                        // Three tabs at 2.0x text scale do not fit a 360dp phone side by side.
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: [
                          Tab(text: l10n?.admin2_teamTabMembers ?? 'Members'),
                          Tab(text: l10n?.admin2_teamTabInvites ?? 'Invites'),
                          Tab(text: l10n?.admin2_teamTabSecurity ?? 'Security'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            AdminTeamMembersTab(
                              members: _members,
                              canManage: _canManage,
                              isWorking: _isWorking,
                              padding: EdgeInsets.all(compact ? 16 : 24),
                              onResetTotp: _resetTotp,
                              onRevoke: _revoke,
                            ),
                            AdminTeamInvitesTab(
                              invites: _invites,
                              canManage: _canManage,
                              callerRole: _role,
                              onAccept: (i) => context.go(
                                  '${RouteNames.adminInviteAccept}?email=${Uri.encodeComponent(i.email)}&role=${Uri.encodeComponent(i.adminRole)}'),
                              onWithdraw: _withdrawInvite,
                              onInvited: _load,
                            ),
                            AdminTeamSecurityTab(
                              members: _members,
                              canManage: _canManage,
                              isWorking: _isWorking,
                              onRemindAll2fa:
                                  _canManage ? _remindAll2fa : null,
                              onResetTotp: _resetTotp,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
