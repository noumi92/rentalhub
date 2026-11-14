import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../data/datasources/admin_support_data_source.dart';

/// One KPI tile on the reports screen.
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
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  )),
        ],
      ),
    );
    if (!compact) return tile;
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(width: (width - 32 - 12) / 2, child: tile);
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
                      context, 'Could not share the CSV file.');
                }
              }
            },
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text('Export CSV'),
    );
  }
}
