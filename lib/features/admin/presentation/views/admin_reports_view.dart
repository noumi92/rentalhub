import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_shell.dart';

/// Phase E (E4) — reports: a date range, live KPIs, bookings by
/// city, top shops, the revenue split from the finance ledger,
/// new customers, and dispute stats, with CSV export. The monthly
/// email needs a Function and a sender decision (plan D8) — it is
/// not in this screen.
class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  AdminReport? _report;
  bool _isLoading = false;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final report = await sl<AdminSupportDataSource>().getReport(
      from: _from,
      to: _to,
    );
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDate: isFrom ? _from : _to,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
    await _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = _report;
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminReports,
      title: 'Reports',
      subtitle: 'KPIs for a date range, with CSV export',
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact: From + To share one row and Export CSV takes
            // its own full-width row — all three side by side
            // overflow at 360px (and worse at 1.35x text scale).
            if (compact) ...[
              Row(
                children: [
                  Expanded(child: _dateButton(isFrom: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _dateButton(isFrom: false)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _exportButton(r),
              ),
            ] else
              Row(
                children: [
                  Expanded(child: _dateButton(isFrom: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _dateButton(isFrom: false)),
                  const SizedBox(width: 12),
                  _exportButton(r),
                ],
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (r == null)
              Text(
                'No data for this range — the report reads the live collections.',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi('Bookings', '${r.totalBookings}', compact),
                  _kpi('Completed', '${r.completedBookings}', compact),
                  _kpi('Booking revenue',
                      l10n.amountRs(formatRs(r.bookingRevenue)), compact),
                  _kpi('Finance income',
                      l10n.amountRs(formatRs(r.financeIncome)), compact),
                  _kpi('Finance expense',
                      l10n.amountRs(formatRs(r.financeExpense)), compact),
                  _kpi('New customers', '${r.newCustomers}', compact),
                  _kpi('Disputes open', '${r.disputesOpen}', compact),
                  _kpi('Disputes resolved', '${r.disputesResolved}', compact),
                ],
              ),
              const SizedBox(height: 20),
              _section('Bookings by city',
                  r.bookingsByCity.entries.map((e) => '${e.key}: ${e.value}')),
              _section('Top shops',
                  r.topShops.map((e) => '${e.key}: ${e.value} bookings')),
              _section('Income by category',
                  r.incomeByCategory.entries.map((e) =>
                      '${e.key}: ${l10n.amountRs(formatRs(e.value))}')),
              _section('Expense by category',
                  r.expenseByCategory.entries.map((e) =>
                      '${e.key}: ${l10n.amountRs(formatRs(e.value))}')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateButton({required bool isFrom}) {
    final date = isFrom ? _from : _to;
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_rounded, size: 18),
      label: Text(
        '${isFrom ? 'From' : 'To'} ${date.toString().substring(0, 10)}',
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () => _pickDate(isFrom: isFrom),
    );
  }

  Widget _exportButton(AdminReport? r) {
    return FilledButton.icon(
      onPressed: r == null
          ? null
          : () async {
              final csv = AdminSupportDataSource.reportCsv(r);
              await SharePlus.instance.share(ShareParams(
                files: [
                  XFile.fromData(
                    utf8.encode(csv),
                    name: 'rentalhub-report.csv',
                    mimeType: 'text/csv',
                  ),
                ],
              ));
            },
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text('Export CSV'),
    );
  }

  Widget _kpi(String label, String value, bool compact) {
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
              style:
                  TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

  Widget _section(String title, Iterable<String> lines) {
    final list = lines.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 6),
          if (list.isEmpty)
            Text('None in this range.',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ...list.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l,
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )),
        ],
      ),
    );
  }
}
