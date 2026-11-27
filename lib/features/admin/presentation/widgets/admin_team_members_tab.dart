import 'package:flutter/material.dart';

import '../../data/datasources/admin_remote_data_source.dart';
import 'admin_team_members_section.dart';

/// Phase 2 (2.5) — the admin team screen's Members tab: the team
/// list with TOTP resets and role revocations. The 2FA banner +
/// Remind-all live on the Security tab now, so `onRemindAll2fa` is
/// left null here and the banner never renders on this tab.
class AdminTeamMembersTab extends StatelessWidget {
  const AdminTeamMembersTab({
    super.key,
    required this.members,
    required this.canManage,
    required this.onResetTotp,
    required this.onRevoke,
    this.isWorking = false,
    this.padding = const EdgeInsets.all(16),
  });

  final List<AdminTeamMember> members;
  final bool canManage;
  final void Function(AdminTeamMember member) onResetTotp;
  final void Function(AdminTeamMember member) onRevoke;
  final bool isWorking;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: AdminTeamMembersSection(
        members: members,
        canManage: canManage,
        isWorking: isWorking,
        onRemindAll2fa: null,
        onResetTotp: onResetTotp,
        onRevoke: onRevoke,
      ),
    );
  }
}
