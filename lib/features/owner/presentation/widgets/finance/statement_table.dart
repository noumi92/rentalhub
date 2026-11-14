import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// The statement's total-due card, above the table.
class StatementTotalCard extends StatelessWidget {
  final int totalDue;

  const StatementTotalCard({super.key, required this.totalDue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.financeStatementTotalDue,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70)),
          Text(l10n.amountRs(formatRs(totalDue)),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  )),
        ],
      ),
    );
  }
}

/// Audit impl (O46): the statement table — Booking / Date / Rent /
/// Paid / Due, one row per booking. Extracted from
/// [OwnerCustomerStatementView] so the view stays under the
/// 250-line cap.
class StatementTable extends StatelessWidget {
  final List<BookingEntity> bookings;

  const StatementTable({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Text header(String text) => Text(text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ));
    Text cell(String text) => Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: header(l10n.financeStatementColBooking)),
          DataColumn(label: header(l10n.financeStatementColDate)),
          DataColumn(
              label: header(l10n.financeStatementColRent), numeric: true),
          DataColumn(
              label: header(l10n.financeStatementColPaid), numeric: true),
          DataColumn(
              label: header(l10n.financeStatementColDue), numeric: true),
        ],
        rows: [
          for (final b in bookings)
            DataRow(cells: [
              DataCell(cell('#${b.bookingId}')),
              DataCell(cell(
                  DateFormat.yMd(Localizations.localeOf(context).languageCode).format(b.pickupTime))),
              DataCell(cell(l10n.amountRs(formatRs(b.totalAmount)))),
              DataCell(cell(l10n.amountRs(formatRs(b.advancePaid)))),
              DataCell(
                  cell(l10n.amountRs(formatRs(b.remainingBalance)))),
            ]),
        ],
      ),
    );
  }
}
