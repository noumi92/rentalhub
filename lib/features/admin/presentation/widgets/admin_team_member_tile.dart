import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../domain/admin_permissions.dart';

/// One row of the admin team list: who they are, their role, whether
/// two-factor authentication is on, and the super-admin actions
/// (reset TOTP, revoke the role).
class AdminTeamMemberTile extends StatelessWidget {
  const AdminTeamMemberTile({
    super.key,
    required this.member,
    required this.canManage,
    required this.onResetTotp,
    required this.onRevoke,
  });

  final AdminTeamMember member;
  final bool canManage;
  final VoidCallback onResetTotp;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: const Icon(Icons.person_rounded,
              size: 22),
        ),
        title: Text(
          member.email.isEmpty ? member.uid : member.email,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              ),
        ),
        subtitle: Text(
          AdminPermissions.label(member.adminRole),
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (member.totpEnabled
                        ? Colors.green.shade700
                        : Colors.amber.shade800)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.totpEnabled ? '2FA on' : '2FA off',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: member.totpEnabled
                        ? Colors.green.shade700
                        : Colors.amber.shade800),
              ),
            ),
            if (canManage) ...[
              IconButton(
                icon: const Icon(Icons.key_rounded, size: 20),
                tooltip: 'Reset two-factor authentication',
                onPressed: onResetTotp,
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_rounded, size: 20),
                tooltip: 'Revoke admin role',
                onPressed: onRevoke,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
