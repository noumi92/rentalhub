import 'dart:convert';

import 'package:flutter/material.dart';
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

  ({DateTime? from, DateTime? to, String label}) get _range {
    final now = DateTime.now();
    switch (_period) {
      case 'last_month':
        final start = DateTime(now.year, now.month - 1);
        return (
          from: start,
          to: DateTime(now.year, now.month),
          label: 'Last month',
        );
      case 'all':
        return (from: null, to: null, label: 'All time');
      case 'this_month':
      default:
        return (
          from: DateTime(now.year, now.month),
          to: DateTime(now.year, now.month + 1),
          label: 'This month',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
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
            Text('P&L Statement',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            DropdownButton<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              value: _period,
              items: const [
                DropdownMenuItem(
                    value: 'this_month', child: Text('This month')),
                DropdownMenuItem(
                    value: 'last_month', child: Text('Last month')),
                DropdownMenuItem(value: 'all', child: Text('All time')),
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
              _row('Booking revenue', revenue),
              _row('Other income', totals.income),
              _row('Expenses', -totals.expenses),
              const Divider(height: 16),
              _row('Net profit', net, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Export P&L as CSV (opens in Excel)'),
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

  Widget _row(String label, int amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              )),
          Text('Rs. $amount',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
