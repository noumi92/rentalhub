import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
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
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      // Compact: the ListTile trailing (2FA chip + two icon buttons)
      // leaves ~100px for a long email at 360px. Stack instead: the
      // identity row on top, the manage actions as full-width
      // buttons below. Desktop keeps the single-row tile.
      child: compact
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.person_rounded, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.email.isEmpty ? member.uid : member.email,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800),
                            ),
                            Text(
                              AdminPermissions.label(member.adminRole),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      badge,
                    ],
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onResetTotp,
                            icon: const Icon(Icons.key_rounded, size: 18),
                            label: const Text('Reset 2FA'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onRevoke,
                            icon: const Icon(Icons.person_remove_rounded,
                                size: 18),
                            label: const Text('Revoke role'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          : ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.person_rounded, size: 22),
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
                  badge,
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
    return card;
  }
}
