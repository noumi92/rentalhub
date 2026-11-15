import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    // Audit 2026-11-15 AC-4: green.shade700 was 4.12:1 on white /
    // 4.36:1 on the dark surface and amber.shade800 2.29:1 in light
    // — the readable success/warning text tokens instead.
    final badgeColor = member.totpEnabled
        ? AppColors.successTextFor(Theme.of(context).brightness)
        : AppColors.warningTextFor(Theme.of(context).brightness);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        member.totpEnabled
            ? (l10n?.admin2_team2faOn ?? '2FA on')
            : (l10n?.admin2_team2faOff ?? '2FA off'),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: badgeColor),
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
                                  ),
                            ),
                            Text(
                              l10n == null
                                  ? AdminPermissions.label(member.adminRole)
                                  : AdminPermissions.labelL10n(
                                      l10n, member.adminRole),
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
                            // AD-m8: 48dp minimum touch target.
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48)),
                            icon: const Icon(Icons.key_rounded, size: 18),
                            label: Text(l10n?.admin2_teamReset2fa ?? 'Reset 2FA'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onRevoke,
                            // AD-m8: 48dp minimum touch target.
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48)),
                            icon: const Icon(Icons.person_remove_rounded,
                                size: 18),
                            label: Text(l10n?.admin2_teamRevokeRole ?? 'Revoke role'),
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
                    ),
              ),
              subtitle: Text(
                l10n == null
                    ? AdminPermissions.label(member.adminRole)
                    : AdminPermissions.labelL10n(l10n, member.adminRole),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  badge,
                  if (canManage) ...[
                    IconButton(
                      icon: const Icon(Icons.key_rounded, size: 20),
                      tooltip: l10n?.admin2_teamResetTotpTooltip ??
                          'Reset two-factor authentication',
                      onPressed: onResetTotp,
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_remove_rounded, size: 20),
                      tooltip: l10n?.admin2_teamRevokeTooltip ??
                          'Revoke admin role',
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
