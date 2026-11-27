import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/money_format.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import 'admin_list_card.dart';

/// One KPI tile on the reports screen.
///
/// Phase 4 (4.1) — this is the shared [AdminFactTile] now (same
/// tile the shop detail used as `_fact`, radius 12 / padding 12x10
/// / label 11 / value 15); only the compact two-per-row width
/// rule lives here.
class AdminReportKpi extends StatelessWidget {
  const AdminReportKpi({
    super.key,
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Compact: two tiles per row with a bounded width — an
    // intrinsic-width tile ('Booking revenue Rs. 1,234,567') can
    // exceed 360px on its own. Desktop keeps intrinsic widths.
    final tile = AdminFactTile(label: label, value: value);
    if (!compact) return tile;
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(width: (width - 32 - 12) / 2, child: tile);
  }
}

/// The KPI grid on the reports screen: the eight tiles, two per
/// row on compact screens. Extracted from [AdminReportsView] so
/// the view stays under the 250-line cap with the Phase 4 trend
/// and charts.
class AdminReportKpiGrid extends StatelessWidget {
  const AdminReportKpiGrid({
    super.key,
    required this.report,
    required this.compact,
  });

  final AdminReport report;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = report;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        AdminReportKpi(
            label: l10n.admin2_reportsBookings,
            value: '${r.totalBookings}',
            compact: compact),
        AdminReportKpi(
            label: l10n.admin2_reportsCompleted,
            value: '${r.completedBookings}',
            compact: compact),
        AdminReportKpi(
            label: l10n.admin2_reportsRevenue,
            value: l10n.amountRs(formatRs(r.bookingRevenue)),
            compact: compact),
        AdminReportKpi(
            label: l10n.admin2_reportsIncome,
            value: l10n.amountRs(formatRs(r.financeIncome)),
            compact: compact),
        AdminReportKpi(
            label: l10n.admin2_reportsExpense,
            value: l10n.amountRs(formatRs(r.financeExpense)),
            compact: compact),
        AdminReportKpi(
            label: l10n.admin2_reportsNewCustomers,
            value: '${r.newCustomers}',
            compact: compact),
        AdminReportKpi(
            label: l10n.admin2_reportsDisputesOpen,
            value: '${r.disputesOpen}',
            compact: compact),
        AdminReportKpi(
            label: l10n.admin2_reportsDisputesResolved,
            value: '${r.disputesResolved}',
            compact: compact),
      ],
    );
  }
}

/// The From/To date button on the reports screen: locale-aware label
/// (was a raw `toString().substring(0, 10)`) and a 48dp target.
class AdminReportDateButton extends StatelessWidget {
  const AdminReportDateButton({
    super.key,
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_rounded, size: 18),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      label: Text(
        '$label ${DateFormat.yMd(locale).format(date)}',
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: onPressed,
    );
  }
}

/// The From/To date range on the reports screen, with the range
/// error underneath (AD-m10): picking From after To is rejected in
/// the view, and the message renders here so the row stays one
/// widget. Compact stacks the buttons; desktop keeps them in a row.
class AdminReportDateRange extends StatelessWidget {
  const AdminReportDateRange({
    super.key,
    required this.from,
    required this.to,
    required this.rangeError,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final DateTime from;
  final DateTime to;
  final String? rangeError;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: AdminReportDateButton(
                    label: AppLocalizations.of(context)!.admin2_reportsFrom,
                    date: from,
                    onPressed: onPickFrom)),
            const SizedBox(width: 12),
            Expanded(
                child: AdminReportDateButton(
                    label: AppLocalizations.of(context)!.admin2_reportsTo,
                    date: to,
                    onPressed: onPickTo)),
          ],
        ),
        if (rangeError != null) ...[
          const SizedBox(height: 8),
          Text(rangeError!,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}

/// The reports CSV export button: disabled while there is no report
/// (the empty state above explains why), and a share failure shows
/// an error instead of failing silently.
class AdminReportExportButton extends StatelessWidget {
  const AdminReportExportButton({super.key, required this.report});

  final AdminReport? report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    return FilledButton.icon(
      onPressed: r == null
          ? null
          : () async {
              final csv = AdminSupportDataSource.reportCsv(r);
              try {
                await SharePlus.instance.share(ShareParams(
                  files: [
                    XFile.fromData(
                      utf8.encode(csv),
                      name: 'rentalhub-report.csv',
                      mimeType: 'text/csv',
                    ),
                  ],
                ));
              } catch (_) {
                if (context.mounted) {
                  AppFeedback.showError(
                      context,
                      AppLocalizations.of(context)!
                          .admin2_reportsCsvShareFailed);
                }
              }
            },
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      icon: const Icon(Icons.download_rounded, size: 18),
      label: Text(AppLocalizations.of(context)!.admin2_reportsExportCsv),
    );
  }
}

/// The reports PDF summary button (F-m12, plan E4): the same KPIs
/// and breakdowns as the screen, as a PDF file. Disabled while
/// there is no report. Shares through the same path as the CSV, so
/// on web it downloads (SharePlus falls back to a download when
/// the browser cannot share files).
class AdminReportPdfButton extends StatelessWidget {
  const AdminReportPdfButton({super.key, required this.report});

  final AdminReport? report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: r == null
          ? null
          : () async {
              try {
                final pdf = await AdminSupportDataSource.reportPdf(r);
                await SharePlus.instance.share(ShareParams(
                  files: [
                    XFile.fromData(
                      pdf,
                      name: 'rentalhub-report.pdf',
                      mimeType: 'application/pdf',
                    ),
                  ],
                ));
              } catch (_) {
                if (context.mounted) {
                  AppFeedback.showError(context,
                      l10n?.adminAuditPdfFailed ?? 'Could not share the PDF file.');
                }
              }
            },
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
      label: Text(l10n?.adminAuditExportPdf ?? 'Export PDF'),
    );
  }
}
