import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';

/// Phase 2 (2.5) — the admin team screen's Security tab: the
/// two-factor authentication state of the team. Members with 2FA off
/// are listed with a Remind-all action and a per-member TOTP reset;
/// the members list itself (with revocations) stays on the Members
/// tab, so this tab owns only the 2FA workflow.
class AdminTeamSecurityTab extends StatelessWidget {
  const AdminTeamSecurityTab({
    super.key,
    required this.members,
    required this.canManage,
    required this.onResetTotp,
    this.onRemindAll2fa,
    this.isWorking = false,
  });

  final List<AdminTeamMember> members;
  final bool canManage;
  final void Function(AdminTeamMember member) onResetTotp;

  /// "Remind all" for the 2FA-off members. Null hides the action
  /// (non-managers never see it).
  final VoidCallback? onRemindAll2fa;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totpOff = members.where((m) => !m.totpEnabled).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n?.admin2_teamSecurityTitle ?? 'Two-factor authentication',
              style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          if (totpOff.isEmpty)
            Text(l10n?.admin2_teamSecurityAllOn ??
                    'Every admin has two-factor authentication on.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))
          else ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n?.admin2_teamTotpOffBanner(totpOff.length) ??
                        '${totpOff.length} team member(s) have two-factor authentication off.',
                  ),
                ),
                if (canManage && onRemindAll2fa != null)
                  TextButton(
                    onPressed: isWorking ? null : onRemindAll2fa,
                    child: Text(l10n?.admin2_teamTotpRemindAll ?? 'Remind all'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...totpOff.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.email,
                                style: const TextStyle(fontSize: 13)),
                            Text(m.adminRole,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (canManage)
                        OutlinedButton(
                          onPressed:
                              isWorking ? null : () => onResetTotp(m),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          child: Text(l10n?.admin2_teamReset2fa ??
                              'Reset 2FA'),
                        ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
