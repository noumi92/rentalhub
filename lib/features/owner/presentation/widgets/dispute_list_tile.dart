import 'package:flutter/material.dart';

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

  static String statusLabel(String status) {
    switch (status) {
      case 'in_review':
        return 'In review';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Open';
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

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
          dispute.category.isEmpty ? 'Dispute' : dispute.category,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          'Booking ${dispute.bookingId} • ${dispute.customerName ?? dispute.customerId ?? 'Customer'}'
          '${dispute.createdAt == null ? '' : '\n${formatDate(dispute.createdAt)}'}',
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
            statusLabel(dispute.status),
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
