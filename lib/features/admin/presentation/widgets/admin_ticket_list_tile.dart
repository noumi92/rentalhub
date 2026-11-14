import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
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
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: breached
                ? danger.withValues(alpha: 0.4)
                : Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: const Icon(
            Icons.support_agent_rounded,
          ),
        ),
        title: Text(
            t.message.length > 80
                ? '${t.message.substring(0, 80)}…'
                : t.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14,
                )),
        subtitle: Text(
          '${t.priority.toUpperCase()} • ${humanizeStatus(t.status, l10n)} • ${l10n == null ? t.slaText() : t.slaTextL10n(l10n)}'
          '${t.bookingId == null ? '' : ' • ${l10n?.admin2_ticketLinkedBooking ?? 'Linked booking'}'}',
          style: TextStyle(
              fontSize: 12,
              color: breached
                  ? danger
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight:
                  breached ? FontWeight.w500 : FontWeight.normal),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
