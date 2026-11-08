import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import  '../../../../bookings/domain/entities/booking_entity.dart';
import  '../../../../finance/domain/entities/finance_transfer_entity.dart';
import  '../../../../finance/utils/finance_summary.dart';
import  '../../../../finance/utils/pnl_csv.dart';

/// Phase B (H5): the P&L statement for a period, with a CSV export
/// that opens in Excel. The booking revenue comes from the
/// bookings; the rest from the ledger.
class FinancePnLReport extends StatefulWidget {
  final String shopName;
  final List<BookingEntity> bookings;
  final List<FinanceTransferEntity> transfers;

  const FinancePnLReport({
    super.key,
    required this.shopName,
    required this.bookings,
    required this.transfers,
  });

  @override
  State<FinancePnLReport> createState() => _FinancePnLReportState();
}

class _FinancePnLReportState extends State<FinancePnLReport> {
  String _period = 'this_month';

  // Phase F: the period labels are localized (the dropdown already
  // was — only the range record still carried English literals).
  ({DateTime? from, DateTime? to, String label}) _range(
      AppLocalizations l10n) {
    final now = DateTime.now();
    switch (_period) {
      case 'last_month':
        final start = DateTime(now.year, now.month - 1);
        return (
          from: start,
          to: DateTime(now.year, now.month),
          label: l10n.financeLastMonth,
        );
      case 'all':
        return (from: null, to: null, label: l10n.financeAllTime);
      case 'this_month':
      default:
        return (
          from: DateTime(now.year, now.month),
          to: DateTime(now.year, now.month + 1),
          label: l10n.financeThisMonth,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final range = _range(l10n);
    final totals = FinanceSummary.periodTotals(
      widget.transfers,
      from: range.from,
      to: range.to,
    );
    final revenue = widget.bookings
        .where((b) =>
            (b.status == 'completed' ||
                b.status == 'paid' ||
                b.status == 'active') &&
            (range.from == null || !b.pickupTime.isBefore(range.from!)) &&
            (range.to == null || b.pickupTime.isBefore(range.to!)))
        .fold<int>(0, (total, b) => total + b.totalAmount);
    final net = revenue + totals.income - totals.expenses;
    final periodTransfers = widget.transfers
        .where((t) =>
            (range.from == null || !t.createdAt.isBefore(range.from!)) &&
            (range.to == null || t.createdAt.isBefore(range.to!)))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.financePnlTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            DropdownButton<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              value: _period,
              items: [
                DropdownMenuItem(
                    value: 'this_month',
                    child: Text(l10n.financeThisMonth)),
                DropdownMenuItem(
                    value: 'last_month',
                    child: Text(l10n.financeLastMonth)),
                DropdownMenuItem(
                    value: 'all', child: Text(l10n.financeAllTime)),
              ],
              onChanged: (v) => setState(() => _period = v ?? 'this_month'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _row(l10n, l10n.financePnlBookingRevenue, revenue),
              _row(l10n, l10n.financePnlOtherIncome, totals.income),
              _row(l10n, l10n.financePnlExpenses, -totals.expenses),
              const Divider(height: 16),
              _row(l10n, l10n.financePnlNetProfit, net, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(l10n.financePnlExport),
            onPressed: () async {
              final csv = PnLCsv.build(
                shopName: widget.shopName,
                periodLabel: range.label,
                bookingRevenue: revenue,
                ledgerIncome: totals.income,
                expenses: totals.expenses,
                transfers: periodTransfers,
              );
              await SharePlus.instance.share(
                ShareParams(
                  files: [
                    XFile.fromData(
                      utf8.encode(csv),
                      name: 'rentalhub-pnl-${range.label.toLowerCase().replaceAll(' ', '-')}.csv',
                      mimeType: 'text/csv',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(AppLocalizations l10n, String label, int amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              )),
          Text(l10n.amountRs(amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
