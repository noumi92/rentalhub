import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';

/// One row of the owner's disputes inbox: the dispute category, the
/// booking reference, who filed it, when, and a status chip. The
/// status colours are the rulebook container/on-container token
/// pairs (audit §30) — the old hardcoded Material shades failed
/// WCAG AA in dark mode.
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

  /// Container (chip background) for a status, brightness-aware.
  static Color statusContainer(BuildContext context, String status) {
    final brightness = Theme.of(context).brightness;
    switch (status) {
      case 'in_review':
        return Theme.of(context).colorScheme.primaryContainer;
      case 'resolved':
        return AppColors.successContainerFor(brightness);
      default:
        return AppColors.warningContainerFor(brightness);
    }
  }

  /// Text/icon colour on [statusContainer] for a status.
  static Color statusOnContainer(BuildContext context, String status) {
    final brightness = Theme.of(context).brightness;
    switch (status) {
      case 'in_review':
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case 'resolved':
        return AppColors.successOnContainerFor(brightness);
      default:
        return AppColors.warningOnContainerFor(brightness);
    }
  }

  /// Kept for the detail sheet: the on-container colour, which is
  /// what the old `statusColor` callers used as the chip text/icon
  /// colour. Needs a context now that the tokens are brightness-
  /// aware.
  static Color statusColor(BuildContext context, String status) =>
      statusOnContainer(context, status);

  static String formatDate(AppLocalizations l10n, DateTime? date) {
    if (date == null) return '';
    final months = [
      l10n.disputesMonthJan, l10n.disputesMonthFeb, l10n.disputesMonthMar, l10n.disputesMonthApr, l10n.disputesMonthMay, l10n.disputesMonthJun,
      l10n.disputesMonthJul, l10n.disputesMonthAug, l10n.disputesMonthSep, l10n.disputesMonthOct, l10n.disputesMonthNov, l10n.disputesMonthDec,
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Compact duration ("2d" / "5h" / "30m") for the
  /// `disputeFiledAgo` / `disputeSlaLeft` labels.
  static String durationLabel(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes < 1 ? 1 : d.inMinutes}m';
  }

  /// Audit §30: "Filed {time} ago • {time} left" (72h SLA) under
  /// the booking line, so urgency is visible at a glance.
  static String? slaLine(AppLocalizations l10n, DateTime? createdAt) {
    if (createdAt == null) return null;
    final age = DateTime.now().difference(createdAt);
    final left = const Duration(hours: 72) - age;
    final leftLabel =
        durationLabel(left.isNegative ? Duration.zero : left);
    return '${l10n.disputeFiledAgo(durationLabel(age))} • ${l10n.disputeSlaLeft(leftLabel)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final container = statusContainer(context, dispute.status);
    final onContainer = statusOnContainer(context, dispute.status);
    final sla = slaLine(l10n, dispute.createdAt);
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
          backgroundColor: container,
          child: Icon(Icons.report_problem_outlined,
              color: onContainer, size: 22),
        ),
        title: Text(
          dispute.category.isEmpty ? l10n.disputesFallbackTitle : dispute.category,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          l10n.disputesBookingLine(dispute.bookingId, dispute.customerName ?? dispute.customerId ?? l10n.requestsCustomerFallback) +
          (sla == null ? '' : '\n$sla'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        isThreeLine: sla != null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: container,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusLabel(l10n, dispute.status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: onContainer,
            ),
          ),
        ),
      ),
    );
  }
}
