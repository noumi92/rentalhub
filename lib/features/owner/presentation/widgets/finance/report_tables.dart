import 'package:flutter/material.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// Audit impl (O38): the all-cars Car — Bookings — Earnings table
/// and the customer-history table. Rows are (name, count,
/// earnings) triples computed by [OwnerReportsView]. Extracted so
/// the view stays under the 250-line cap.
class ReportCarTable extends StatelessWidget {
  final List<(String, int, int)> rows;

  const ReportCarTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ReportTable(
      title: l10n.reportCarTableTitle,
      emptyText: l10n.reportNoCars,
      rows: rows,
    );
  }
}

class ReportCustomerTable extends StatelessWidget {
  final List<(String, int, int)> rows;

  const ReportCustomerTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ReportTable(
      title: l10n.reportCustomerTableTitle,
      emptyText: l10n.reportNoCustomers,
      rows: rows,
    );
  }
}

class _ReportTable extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<(String, int, int)> rows;

  const _ReportTable({
    required this.title,
    required this.emptyText,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text(emptyText,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        for (final row in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(row.$1, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(l10n.reportCarBookings(row.$2)),
            trailing: Text(l10n.amountRs(formatRs(row.$3)),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
          ),
      ],
    );
  }
}
