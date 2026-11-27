import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import 'admin_list_card.dart';
import 'admin_status_chip.dart';

/// One ticket row in the admin inbox: the message, priority,
/// status, minute-precise SLA countdown, and a "Linked booking"
/// marker when the ticket carries one. The row turns red once the
/// SLA is breached. Extracted from the view so the view stays
/// under the 250-line cap.
class AdminTicketListTile extends StatelessWidget {
  const AdminTicketListTile({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final l10n = AppLocalizations.of(context);
    final breached = t.createdAt != null &&
        DateTime.now()
            .isAfter(t.createdAt!.add(Duration(hours: t.slaHours)));
    final danger = adminStatusColor(context, AdminStatusTone.danger);
    // Phase 4 (4.1) — the shared [AdminListCard] shell; the
    // breached-SLA red border survives through [borderColor].
    return AdminListCard(
      icon: Icons.support_agent_rounded,
      title: t.message.length > 80
          ? '${t.message.substring(0, 80)}…'
          : t.message,
      subtitle:
          '${t.priority.toUpperCase()} • ${humanizeStatus(t.status, l10n)} • ${l10n == null ? t.slaText() : t.slaTextL10n(l10n)}'
          '${t.bookingId == null ? '' : ' • ${l10n?.admin2_ticketLinkedBooking ?? 'Linked booking'}'}',
      borderColor:
          breached ? danger.withValues(alpha: 0.4) : null,
      subtitleColor: breached ? danger : null,
      subtitleFontWeight: breached ? FontWeight.w500 : null,
      trailing: adminListChevron,
      onTap: onTap,
    );
  }
}
