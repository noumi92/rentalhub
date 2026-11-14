import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_detail_section.dart';
import '../widgets/admin_report_widgets.dart';
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
  bool _hasError = false;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
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
                  Expanded(
                      child: AdminReportDateButton(
                          label: 'From',
                          date: _from,
                          onPressed: () => _pickDate(isFrom: true))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: AdminReportDateButton(
                          label: 'To',
                          date: _to,
                          onPressed: () => _pickDate(isFrom: false))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AdminReportExportButton(report: r),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                      child: AdminReportDateButton(
                          label: 'From',
                          date: _from,
                          onPressed: () => _pickDate(isFrom: true))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: AdminReportDateButton(
                          label: 'To',
                          date: _to,
                          onPressed: () => _pickDate(isFrom: false))),
                  const SizedBox(width: 12),
                  AdminReportExportButton(report: r),
                ],
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const AppLoadingState()
            else if (_hasError)
              AppErrorState(
                message: 'Could not load the report.',
                onRetry: _load,
              )
            else if (r == null)
              const AppEmptyState(
                title: 'No data for this range',
                message: 'The report reads the live collections.',
              )
            else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AdminReportKpi(
                      label: 'Bookings',
                      value: '${r.totalBookings}',
                      compact: compact),
                  AdminReportKpi(
                      label: 'Completed',
                      value: '${r.completedBookings}',
                      compact: compact),
                  AdminReportKpi(
                      label: 'Booking revenue',
                      value: l10n.amountRs(formatRs(r.bookingRevenue)),
                      compact: compact),
                  AdminReportKpi(
                      label: 'Finance income',
                      value: l10n.amountRs(formatRs(r.financeIncome)),
                      compact: compact),
                  AdminReportKpi(
                      label: 'Finance expense',
                      value: l10n.amountRs(formatRs(r.financeExpense)),
                      compact: compact),
                  AdminReportKpi(
                      label: 'New customers',
                      value: '${r.newCustomers}',
                      compact: compact),
                  AdminReportKpi(
                      label: 'Disputes open',
                      value: '${r.disputesOpen}',
                      compact: compact),
                  AdminReportKpi(
                      label: 'Disputes resolved',
                      value: '${r.disputesResolved}',
                      compact: compact),
                ],
              ),
              const SizedBox(height: 20),
              AdminDetailSection(
                  title: 'Bookings by city',
                  lines: r.bookingsByCity.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .toList(),
                  emptyText: 'None in this range.',
                  muted: true),
              AdminDetailSection(
                  title: 'Top shops',
                  lines: r.topShops
                      .map((e) => '${e.key}: ${e.value} bookings')
                      .toList(),
                  emptyText: 'None in this range.',
                  muted: true),
              AdminDetailSection(
                  title: 'Income by category',
                  lines: r.incomeByCategory.entries
                      .map((e) =>
                          '${e.key}: ${l10n.amountRs(formatRs(e.value))}')
                      .toList(),
                  emptyText: 'None in this range.',
                  muted: true),
              AdminDetailSection(
                  title: 'Expense by category',
                  lines: r.expenseByCategory.entries
                      .map((e) =>
                          '${e.key}: ${l10n.amountRs(formatRs(e.value))}')
                      .toList(),
                  emptyText: 'None in this range.',
                  muted: true),
            ],
          ],
        ),
      ),
    );
  }




}
