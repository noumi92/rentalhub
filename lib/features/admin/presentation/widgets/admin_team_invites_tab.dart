import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import 'admin_invite_form.dart';
import 'admin_team_invites_section.dart';

/// Phase 2 (2.5) — the admin team screen's Invites tab: the pending
/// invites and, for a super admin, the invite form.
class AdminTeamInvitesTab extends StatelessWidget {
  const AdminTeamInvitesTab({
    super.key,
    required this.invites,
    required this.canManage,
    required this.callerRole,
    required this.onAccept,
    required this.onWithdraw,
    required this.onInvited,
  });

  final List<AdminInvite> invites;
  final bool canManage;
  final String? callerRole;
  final void Function(AdminInvite invite) onAccept;
  final void Function(AdminInvite invite) onWithdraw;
  final VoidCallback onInvited;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTeamInvitesSection(
            invites: invites,
            canManage: canManage,
            onAccept: onAccept,
            onWithdraw: onWithdraw,
          ),
          if (canManage) ...[
            const SizedBox(height: 24),
            Text(l10n?.admin2_teamInviteButton ?? 'Invite an admin',
                style: const TextStyle(
                    fontSize: 15,
                    )),
            const SizedBox(height: 10),
            AdminInviteForm(
              callerRole: callerRole,
              onInvited: onInvited,
            ),
          ],
        ],
      ),
    );
  }
}
