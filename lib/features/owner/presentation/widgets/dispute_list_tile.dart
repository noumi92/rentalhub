import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../customer/data/datasources/dispute_remote_data_source.dart';

/// One row of the owner's disputes inbox: the dispute category, the
/// booking reference, who filed it, when, and a status chip. The
/// status colours are the inbox's own: open needs attention (amber),
/// in review is being worked on (blue), resolved is done (green).
class DisputeListTile extends StatelessWidget {
  const DisputeListTile({
    super.key,
    required this.dispute,
    required this.onTap,
  });

  final DisputeRecord dispute;
  final VoidCallback onTap;

  static String statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'in_review':
        return l10n.inReview;
      case 'resolved':
        return l10n.disputeResolved;
      default:
        return l10n.disputeOpen;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'in_review':
        return Colors.blue.shade700;
      case 'resolved':
        return Colors.green.shade700;
      default:
        return Colors.amber.shade800;
    }
  }

  static String formatDate(AppLocalizations l10n, DateTime? date) {
    if (date == null) return '';
    final months = [
      l10n.disputesMonthJan, l10n.disputesMonthFeb, l10n.disputesMonthMar, l10n.disputesMonthApr, l10n.disputesMonthMay, l10n.disputesMonthJun,
      l10n.disputesMonthJul, l10n.disputesMonthAug, l10n.disputesMonthSep, l10n.disputesMonthOct, l10n.disputesMonthNov, l10n.disputesMonthDec,
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final color = statusColor(dispute.status);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.report_problem_outlined, color: color, size: 22),
        ),
        title: Text(
          dispute.category.isEmpty ? l10n.disputesFallbackTitle : dispute.category,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          l10n.disputesBookingLine(dispute.bookingId, dispute.customerName ?? dispute.customerId ?? l10n.requestsCustomerFallback) +
          (dispute.createdAt == null ? '' : '\n${formatDate(l10n, dispute.createdAt)}'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        isThreeLine: dispute.createdAt != null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusLabel(l10n, dispute.status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
