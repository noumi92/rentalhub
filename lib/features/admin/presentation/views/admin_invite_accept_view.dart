import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_shell.dart';

/// The invite accept screen (F-M5): a super admin opens the link
/// shared from an invite (`/admin/accept-invite?email=…&role=…`)
/// and grants the role. The invitee cannot self-grant — `setAdminRole`
/// requires the *caller* to be a super admin, server-side — so this
/// screen is for the super admin, after the invitee's account exists.
/// No email is sent anywhere in this flow yet (there is no
/// invite-mail Function; that needs the Functions deploy): the link
/// is copied from the invite list and shared by hand.
class AdminInviteAcceptView extends StatefulWidget {
  const AdminInviteAcceptView({
    super.key,
    required this.email,
    required this.role,
  });

  final String email;
  final String role;

  /// The shareable accept link for an invite, built from the
  /// current origin (web). Used by the invite tile's copy button.
  static Uri acceptUri({required String email, required String role}) {
    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: RouteNames.adminInviteAccept,
      queryParameters: {'email': email, 'role': role},
    );
  }

  @override
  State<AdminInviteAcceptView> createState() =>
      _AdminInviteAcceptViewState();
}

class _AdminInviteAcceptViewState extends State<AdminInviteAcceptView> {
  AdminInvite? _invite;
  String? _role;
  bool _isLoading = true;
  bool _isGranting = false;
  bool _granted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {}
      final l10n = AppLocalizations.of(context);
      if (user == null) {
        if (mounted) {
          setState(() => _error =
              l10n?.admin2_inviteAcceptSignIn ?? 'Sign in as a super admin first.');
        }
        return;
      }
      final role = await AdminSession.resolveCurrentAdminRole();
      if (role != AdminPermissions.superAdmin) {
        if (mounted) {
          setState(() => _error = l10n?.admin2_inviteAcceptNotSuper ??
              'Only a super admin can grant an admin role.');
        }
        return;
      }
      final invites = await sl<AdminRemoteDataSource>().getInvites();
      final match = invites.where((i) =>
          i.email.toLowerCase() == widget.email.trim().toLowerCase() &&
          i.adminRole == widget.role &&
          !i.accepted &&
          !i.isExpired);
      if (!mounted) return;
      setState(() {
        _role = role;
        _invite = match.isEmpty ? null : match.first;
        if (_invite == null) {
          _error = l10n?.admin2_inviteAcceptNoInvite ??
              'No pending invite matches this link — it may have expired or already been accepted.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            AppLocalizations.of(context)?.admin2_inviteAcceptFailed ??
                'Could not load the invite.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _grant() async {
    final invite = _invite;
    if (invite == null) return;
    setState(() => _isGranting = true);
    try {
      await sl<AdminRemoteDataSource>().setAdminRole(
          email: invite.email,
          adminRole: invite.adminRole,
          callerRole: _role);
      await sl<AdminRemoteDataSource>()
          .markInviteAccepted(invite.id, callerRole: _role);
      if (mounted) setState(() => _granted = true);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
            context,
            AppLocalizations.of(context)?.admin2_inviteAcceptGrantFailed ??
                'Could not grant the role.');
      }
    } finally {
      if (mounted) setState(() => _isGranting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdminShell(
      activeRoute: RouteNames.adminTeam,
      title: l10n?.admin2_inviteAcceptTitle ?? 'Accept invite',
      subtitle: widget.email,
      onRefresh: _load,
      child: _isLoading
          ? const AppLoadingState()
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _load)
              : _granted
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.admin2_inviteAcceptGranted ??
                                'Role granted.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.go(RouteNames.adminTeam),
                            child: Text(l10n?.admin2_inviteAcceptBackToTeam ??
                                'Back to team'),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n?.admin2_inviteAcceptBody(
                                    widget.email,
                                    AdminPermissions.labelL10n(
                                        l10n, widget.role)) ??
                                'Grant ${AdminPermissions.label(widget.role)} to ${widget.email}?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n?.admin2_inviteAcceptHint ??
                                'The invitee must already have an account. Granting gives them admin access immediately.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _isGranting ? null : _grant,
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 48)),
                            child: Text(_isGranting
                                ? (l10n?.admin2_inviteAcceptGranting ??
                                    'Granting…')
                                : (l10n?.admin2_inviteAcceptGrant ??
                                    'Grant role')),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
