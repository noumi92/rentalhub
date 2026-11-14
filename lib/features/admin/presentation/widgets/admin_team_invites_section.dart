import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import 'admin_invite_form.dart';

/// The "Pending invites" section of the admin team screen, extracted
/// so the view stays under the 250-line cap.
class AdminTeamInvitesSection extends StatelessWidget {
  const AdminTeamInvitesSection({
    super.key,
    required this.invites,
    required this.canManage,
    required this.onWithdraw,
    required this.onAccept,
  });

  final List<AdminInvite> invites;
  final bool canManage;
  final void Function(AdminInvite invite) onWithdraw;
  final void Function(AdminInvite invite) onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = invites.where((i) => !i.accepted).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n?.admin2_teamInvitesTitle ?? 'Pending invites',
            style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          Text(l10n?.admin2_teamInvitesEmpty ?? 'No pending invites.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        else
          ...pending.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminInviteTile(
                  invite: i,
                  canManage: canManage,
                  onWithdraw: () => onWithdraw(i),
                  onAccept: () => onAccept(i),
                ),
              )),
      ],
    );
  }
}
