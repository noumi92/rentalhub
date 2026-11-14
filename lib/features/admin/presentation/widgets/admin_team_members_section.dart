import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
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
    this.onRemindAll2fa,
    this.isWorking = false,
  });

  final List<AdminTeamMember> members;
  final bool canManage;
  final void Function(AdminTeamMember member) onResetTotp;
  final void Function(AdminTeamMember member) onRevoke;

  /// F-m4: "Remind all" for the 2FA-off banner. Null hides the
  /// banner (non-managers never see it — the view only passes it
  /// when the signed-in admin can manage the team).
  final VoidCallback? onRemindAll2fa;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // F-m4: the 2FA-off reminder banner — only the count used to
    // exist, as a chip per member, with no way to remind anyone.
    final totpOff = members.where((m) => !m.totpEnabled).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n?.admin2_teamMembersTitle ?? 'Team members',
            style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 10),
        if (canManage && onRemindAll2fa != null && totpOff > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n?.admin2_teamTotpOffBanner(totpOff) ??
                        '$totpOff team member(s) have two-factor authentication off.',
                  ),
                ),
                TextButton(
                  onPressed: isWorking ? null : onRemindAll2fa,
                  child: Text(l10n?.admin2_teamTotpRemindAll ?? 'Remind all'),
                ),
              ],
            ),
          ),
        if (members.isEmpty)
          Text(
              l10n?.admin2_teamMembersEmpty ??
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
