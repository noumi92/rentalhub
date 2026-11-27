import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/email_validation.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../views/admin_invite_accept_view.dart';

/// The invite form on the team screen, extracted from AdminTeamView
/// so the view stays under the 250-line cap. It owns the whole
/// invite flow — email, role picker, the 48-hour note, and the save
/// button — and tells the view to reload via [onInvited].
///
/// F-M5 / AD-m14: the email is validated for real before anything
/// is saved, and the button says "Save invite", not "Send invite":
/// no email is sent (there is no invite-mail Function yet — that
/// needs the Functions deploy). The accept link is copied from the
/// invite tile and shared by hand.
class AdminInviteForm extends StatefulWidget {
  const AdminInviteForm({
    super.key,
    required this.callerRole,
    required this.onInvited,
  });

  /// The signed-in admin's role (F-C1: createInvite enforces
  /// manageTeam and throws otherwise).
  final String? callerRole;
  final VoidCallback onInvited;

  @override
  State<AdminInviteForm> createState() => _AdminInviteFormState();
}

class _AdminInviteFormState extends State<AdminInviteForm> {
  final _emailController = TextEditingController();
  String _inviteRole = AdminPermissions.operations;
  bool _isWorking = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (!isValidEmailAddress(email)) {
      AppFeedback.showError(context,
          l10n?.admin2_teamEmailInvalid ?? 'Enter a valid email address.');
      return;
    }
    setState(() => _isWorking = true);
    try {
      // F-M5/F-m11: createInvite throws on Firestore failure now,
      // so the audit log below only ever records an invite that was
      // actually persisted, under its Firestore document id.
      await sl<AdminRemoteDataSource>().createInvite(
          email: email,
          adminRole: _inviteRole,
          callerRole: widget.callerRole);
      _emailController.clear();
      widget.onInvited();
      if (mounted) {
        AppFeedback.showSuccess(
            context,
            l10n?.admin2_teamInviteSaved(email) ??
                'Invite saved for $email. No email is sent yet — share the accept link from the invite list.');
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context,
            l10n?.admin2_teamInviteFailed ?? 'Could not save the invite.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText:
                    l10n?.admin2_teamInviteEmail ?? 'Email address',
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // isExpanded: the button must fill the field width —
              // at 2.0x text scale the intrinsic-width row of the
              // selected item + arrow overflows the field.
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _inviteRole,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: AdminPermissions.allRoles
                  .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(l10n == null
                          ? AdminPermissions.label(r)
                          : AdminPermissions.labelL10n(l10n, r))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _inviteRole = v);
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.admin2_teamInviteHint ??
                  'Invites expire after 48 hours. The invitee creates their account first, then a super admin grants the role.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isWorking ? null : _invite,
              // AD-m8: 48dp minimum touch target.
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(_isWorking
                  ? (l10n?.admin2_saving ?? 'Saving…')
                  : (l10n?.admin2_teamInviteSave ?? 'Save invite')),
            ),
          ],
        ),
      ),
    );
  }
}

/// One pending invite: who it is for, which role, and whether it has
/// expired — with the withdraw action for a super admin, plus the
/// accept action and a copy-accept-link button (F-M5: the link is
/// how the invite reaches the invitee until invite emails exist).
class AdminInviteTile extends StatelessWidget {
  const AdminInviteTile({
    super.key,
    required this.invite,
    required this.canManage,
    required this.onWithdraw,
    required this.onAccept,
  });

  final AdminInvite invite;
  final bool canManage;
  final VoidCallback onWithdraw;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // AD-m14: the expiry is formatted for the admin's locale, not
    // the ambiguous `day/month/year`.
    final expires = invite.expiresAt == null
        ? ''
        : DateFormat.yMd(Localizations.localeOf(context).languageCode)
            .format(invite.expiresAt!);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invite.email, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              '${l10n == null ? AdminPermissions.label(invite.adminRole) : AdminPermissions.labelL10n(l10n, invite.adminRole)} • '
              '${invite.isExpired ? (l10n?.admin2_teamInviteExpired ?? 'Expired') : (l10n?.admin2_teamInviteExpires(expires) ?? 'Expires $expires')}',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (canManage)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: onAccept,
                    child: Text(l10n?.admin2_teamInviteAccept ?? 'Accept'),
                  ),
                  IconButton(
                    tooltip: l10n?.admin2_teamInviteCopyLink ??
                        'Copy accept link',
                    icon: const Icon(Icons.link_outlined),
                    onPressed: () async {
                      final uri = AdminInviteAcceptView.acceptUri(
                          email: invite.email, role: invite.adminRole);
                      await Clipboard.setData(
                          ClipboardData(text: uri.toString()));
                      if (context.mounted) {
                        AppFeedback.showSuccess(
                            context,
                            l10n?.admin2_teamInviteLinkCopied ??
                                'Accept link copied.');
                      }
                    },
                  ),
                  TextButton(
                    onPressed: onWithdraw,
                    child: Text(
                        l10n?.admin2_teamInviteWithdraw ?? 'Withdraw'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
