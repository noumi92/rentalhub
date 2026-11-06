import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../domain/admin_permissions.dart';

/// The invite form on the team screen, extracted from AdminTeamView
/// so the view stays under the 250-line cap: email field, role picker,
/// the 48-hour note, and the send button.
class AdminInviteForm extends StatelessWidget {
  const AdminInviteForm({
    super.key,
    required this.emailController,
    required this.inviteRole,
    required this.onRoleChanged,
    required this.isWorking,
    required this.onInvite,
  });

  final TextEditingController emailController;
  final String inviteRole;
  final ValueChanged<String> onRoleChanged;
  final bool isWorking;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email address',
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: inviteRole,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: AdminPermissions.allRoles
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(AdminPermissions.label(r))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onRoleChanged(v);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Invites expire after 48 hours. The invitee creates their account first, then a super admin grants the role.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isWorking ? null : onInvite,
              child: Text(isWorking ? 'Sending…' : 'Send invite'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One pending invite: who it is for, which role, and whether it has
/// expired — with the withdraw action for a super admin.
class AdminInviteTile extends StatelessWidget {
  const AdminInviteTile({
    super.key,
    required this.invite,
    required this.canManage,
    required this.onWithdraw,
  });

  final AdminInvite invite;
  final bool canManage;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        title: Text(invite.email,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.midnightNavy)),
        subtitle: Text(
          '${AdminPermissions.label(invite.adminRole)} • '
          '${invite.isExpired ? 'Expired' : 'Expires ${invite.expiresAt?.day}/${invite.expiresAt?.month}/${invite.expiresAt?.year}'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: canManage
            ? TextButton(
                onPressed: onWithdraw,
                child: const Text('Withdraw'),
              )
            : null,
      ),
    );
  }
}
