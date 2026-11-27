import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_detail_section.dart';
import '../widgets/admin_report_charts.dart';
import '../widgets/admin_report_widgets.dart';
import '../widgets/admin_shell.dart';

/// Phase E (E4) — reports: a date range, live KPIs, bookings by
/// city, top shops, the revenue split from the finance ledger,
/// new customers, and dispute stats, with CSV and PDF export. The
/// monthly email needs a Function and a sender decision (plan D8)
/// — it is not in this screen.
class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  AdminReport? _report;
  AdminReport? _previous;
  bool _isLoading = false;
  bool _hasError = false;
  bool _rangeError = false;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Phase 4 (4.2): the trend compares this range against the
      // immediately preceding equal-length period, fetched with
      // the same query — no server aggregation exists for this.
      final ds = sl<AdminSupportDataSource>();
      final report = await ds.getReport(from: _from, to: _to);
      final length = _to.difference(_from);
      final prevTo = _from.subtract(const Duration(days: 1));
      final prevFrom = prevTo.subtract(length);
      final previous = await ds.getReport(from: prevFrom, to: prevTo);
      if (mounted) {
        setState(() {
          _report = report;
          _previous = previous;
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
    final from = isFrom ? picked : _from;
    final to = isFrom ? _to : picked;
    // AD-m10: From after To used to reload and show the empty
    // state ("No data for this range"), misdescribing an invalid
    // range as an empty one. Reject it with an inline error and
    // keep the last valid range instead.
    if (from.isAfter(to)) {
      setState(() => _rangeError = true);
      return;
    }
    setState(() {
      _from = from;
      _to = to;
      _rangeError = false;
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
      title: l10n.admin2_navReports,
      subtitle: l10n.admin2_reportsSubtitle,
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminReportDateRange(
              from: _from,
              to: _to,
              rangeError:
                  _rangeError ? l10n.adminAuditInvalidRange : null,
              onPickFrom: () => _pickDate(isFrom: true),
              onPickTo: () => _pickDate(isFrom: false),
            ),
            const SizedBox(height: 12),
            // Compact: the two export buttons stack full-width —
            // side by side they overflow at 360px.
            if (compact) ...[
              SizedBox(
                width: double.infinity,
                child: AdminReportExportButton(report: r),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AdminReportPdfButton(report: r),
              ),
            ] else
              Row(
                children: [
                  AdminReportExportButton(report: r),
                  const SizedBox(width: 12),
                  AdminReportPdfButton(report: r),
                ],
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const AppLoadingState()
            else if (_hasError)
              AppErrorState(
                message: l10n.admin2_reportsLoadFailed,
                onRetry: _load,
              )
            else if (r == null)
              AppEmptyState(
                title: l10n.admin2_reportsEmptyTitle,
                message: l10n.admin2_reportsEmptyHint,
              )
            else ...[
              AdminReportKpiGrid(report: r, compact: compact),
              // Phase 1 (1.4): booked value is not realised income —
              // the reconciliation note, beside the two KPIs above.
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.admin2_reportsRevenueNote,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              // Phase 4 (4.2): trend vs the previous period, the
              // per-day/month charts, and the cap note when the
              // 1,000-row fetch may have cut rows off.
              if (_previous != null) ...[
                const SizedBox(height: 20),
                AdminReportTrendSection(
                    current: r, previous: _previous!),
              ],
              const SizedBox(height: 20),
              AdminReportCharts(report: r),
              if (r.bookingsTruncated || r.transfersTruncated)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.admin2_reportsTruncatedNote,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 20),
              AdminDetailSection(
                  title: l10n.admin2_reportsByCity,
                  lines: r.bookingsByCity.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .toList(),
                  emptyText: l10n.admin2_reportsNone,
                  muted: true),
              AdminDetailSection(
                  title: l10n.admin2_reportsTopShops,
                  lines: r.topShops
                      .map((e) => l10n.admin2_reportsTopShopsLine(e.key, e.value))
                      .toList(),
                  emptyText: l10n.admin2_reportsNone,
                  muted: true),
              AdminDetailSection(
                  title: l10n.admin2_reportsIncomeByCategory,
                  lines: r.incomeByCategory.entries
                      .map((e) =>
                          '${e.key}: ${l10n.amountRs(formatRs(e.value))}')
                      .toList(),
                  emptyText: l10n.admin2_reportsNone,
                  muted: true),
              AdminDetailSection(
                  title: l10n.admin2_reportsExpenseByCategory,
                  lines: r.expenseByCategory.entries
                      .map((e) =>
                          '${e.key}: ${l10n.amountRs(formatRs(e.value))}')
                      .toList(),
                  emptyText: l10n.admin2_reportsNone,
                  muted: true),
            ],
          ],
        ),
      ),
    );
  }




}
