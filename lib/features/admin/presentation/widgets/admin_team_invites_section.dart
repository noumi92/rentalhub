import 'package:flutter/material.dart';

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
  });

  final List<AdminInvite> invites;
  final bool canManage;
  final void Function(AdminInvite invite) onWithdraw;

  @override
  Widget build(BuildContext context) {
    final pending = invites.where((i) => !i.accepted).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pending invites',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          Text('No pending invites.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        else
          ...pending.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminInviteTile(
                  invite: i,
                  canManage: canManage,
                  onWithdraw: () => onWithdraw(i),
                ),
              )),
      ],
    );
  }
}
