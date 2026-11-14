import 'package:flutter/material.dart';

import '../../data/datasources/admin_remote_data_source.dart';
import 'admin_team_member_tile.dart';

/// The "Team members" section of the admin team screen, extracted so
/// the view stays under the 250-line cap.
class AdminTeamMembersSection extends StatelessWidget {
  const AdminTeamMembersSection({
    super.key,
    required this.members,
    required this.canManage,
    required this.onResetTotp,
    required this.onRevoke,
  });

  final List<AdminTeamMember> members;
  final bool canManage;
  final void Function(AdminTeamMember member) onResetTotp;
  final void Function(AdminTeamMember member) onRevoke;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Team members',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (members.isEmpty)
          Text(
              'No admins found — the team list reads the users who hold an admin role.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        else
          ...members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminTeamMemberTile(
                  member: m,
                  canManage: canManage,
                  onResetTotp: () => onResetTotp(m),
                  onRevoke: () => onRevoke(m),
                ),
              )),
      ],
    );
  }
}
