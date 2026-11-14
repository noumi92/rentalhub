import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/services/admin_audit_service.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_invite_form.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_team_members_section.dart';
import '../widgets/admin_team_invites_section.dart';

/// Phase A (A4) — the admin team screen: who holds an admin role, who
/// still has two-factor authentication off, and (super admin only) the
/// invite form, TOTP resets and role revocations. Invites expire after
/// 48 hours; the grant itself happens through setAdminRole once the
/// invitee's account exists.
class AdminTeamView extends StatefulWidget {
  /// The signed-in admin's role. The router leaves it null and the
  /// view resolves it from the signed-in user; tests pass it directly.
  final String? adminRole;

  const AdminTeamView({super.key, this.adminRole});

  @override
  State<AdminTeamView> createState() => _AdminTeamViewState();
}

class _AdminTeamViewState extends State<AdminTeamView> {
  final _emailController = TextEditingController();
  String _inviteRole = AdminPermissions.operations;

  List<AdminTeamMember> _members = [];
  List<AdminInvite> _invites = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isWorking = false;
  String? _role;

  bool get _canManage =>
      _role == AdminPermissions.superAdmin;

  @override
  void initState() {
    super.initState();
    _role = widget.adminRole;
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_role == null) {
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {}
      if (user != null) {
        _role = await AdminSession.resolveAdminRole(user);
      }
    }
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final ds = sl<AdminRemoteDataSource>();
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

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppFeedback.showError(context, 'Enter a valid email address.');
      return;
    }
    setState(() => _isWorking = true);
    try {
      await sl<AdminRemoteDataSource>()
          .createInvite(email: email, adminRole: _inviteRole);
      await AdminAuditService.logAction(
        action: 'admin_invite_created',
        targetType: 'admin_invite',
        targetId: email,
        detail: 'Invited $email as $_inviteRole (48 h expiry).',
      );
      _emailController.clear();
      await _load();
      if (mounted) {
        AppFeedback.showSuccess(context, 'Invite sent to $email.');
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not send the invite.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String body,
    required Future<void> Function() run,
  }) async {
    if (!await showAdminConfirmDialog(context,
        title: title, body: body)) {
      return;
    }
    setState(() => _isWorking = true);
    try {
      await run();
      await _load();
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not complete that action.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminTeam,
      title: 'Admin Team',
      subtitle: 'Who can run the platform, and with what role',
      onRefresh: _load,
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: 'Could not load the admin team.',
                  onRetry: _load,
                )
              : ListView(
              padding: EdgeInsets.all(compact ? 16 : 24),
              children: [
                if (!_canManage)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Only a super admin can invite, reset two-factor authentication, or revoke a role. You can view the team.',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                AdminTeamMembersSection(
                  members: _members,
                  canManage: _canManage,
                  onResetTotp: (m) => _confirmAction(
                    title: 'Reset two-factor authentication?',
                    body:
                        '${m.email} will have to enrol TOTP again on their next login.',
                    run: () async {
                      await sl<AdminRemoteDataSource>().resetTotp(m.uid);
                      await AdminAuditService.logAction(
                        action: 'totp_reset',
                        targetType: 'admin',
                        targetId: m.uid,
                        detail: 'TOTP reset for ${m.email}.',
                      );
                    },
                  ),
                  onRevoke: (m) => _confirmAction(
                    title: 'Revoke this admin role?',
                    body:
                        '${m.email} will lose admin access and become a customer account.',
                    run: () async {
                      await sl<AdminRemoteDataSource>()
                          .setAdminRole(uid: m.uid, adminRole: null);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                AdminTeamInvitesSection(
                  invites: _invites,
                  canManage: _canManage,
                  onWithdraw: (i) => _confirmAction(
                    title: 'Withdraw this invite?',
                    body:
                        '${i.email} will no longer be able to accept it.',
                    run: () async {
                      await sl<AdminRemoteDataSource>().revokeInvite(i.id);
                      await AdminAuditService.logAction(
                        action: 'admin_invite_revoked',
                        targetType: 'admin_invite',
                        targetId: i.email,
                        detail: 'Invite withdrawn for ${i.email}.',
                      );
                    },
                  ),
                ),
                if (_canManage) ...[
                  const SizedBox(height: 24),
                  const Text('Invite an admin',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          )),
                  const SizedBox(height: 10),
                  AdminInviteForm(
                    emailController: _emailController,
                    inviteRole: _inviteRole,
                    onRoleChanged: (v) =>
                        setState(() => _inviteRole = v),
                    isWorking: _isWorking,
                    onInvite: _invite,
                  ),
                ],
              ],
            ),
    );
  }
}
