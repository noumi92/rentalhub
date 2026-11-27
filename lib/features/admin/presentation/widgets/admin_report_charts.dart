import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../../domain/report_series.dart';

/// Phase 4 (4.2) — the Reports charts (fl_chart, the only chart
/// dependency): bookings per bucket and finance income vs expense
/// per bucket, over the selected date range, bucketed client-side
/// from the already-fetched rows ([AdminReport.series]). Empty
/// ranges render a muted "no data" line instead of a flat chart.
class AdminReportCharts extends StatelessWidget {
  const AdminReportCharts({super.key, required this.report});

  final AdminReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final series = report.series;
    final hasData = series.any((p) =>
        p.bookings > 0 || p.income > 0 || p.expense > 0 || p.revenue > 0);
    if (series.isEmpty || !hasData) {
      return Text(
        l10n.admin2_reportsNoChartData,
        style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartCard(
          title: l10n.admin2_reportsBookingsChart,
          child: _LineChart(
            series: series,
            lines: [
              _ChartLine(
                label: l10n.admin2_reportsBookings,
                color: Theme.of(context).colorScheme.primary,
                values: [for (final p in series) p.bookings.toDouble()],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: l10n.admin2_reportsFinanceChart,
          child: _LineChart(
            series: series,
            isMoney: true,
            lines: [
              _ChartLine(
                label: l10n.admin2_reportsIncome,
                color: Colors.green.shade700,
                values: [for (final p in series) p.income.toDouble()],
              ),
              _ChartLine(
                label: l10n.admin2_reportsExpense,
                color: Theme.of(context).colorScheme.error,
                values: [for (final p in series) p.expense.toDouble()],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartLine {
  const _ChartLine(
      {required this.label, required this.color, required this.values});

  final String label;
  final Color color;
  final List<double> values;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(height: 180, child: child),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.series,
    required this.lines,
    this.isMoney = false,
  });

  final List<AdminReportPoint> series;
  final List<_ChartLine> lines;
  final bool isMoney;

  @override
  Widget build(BuildContext context) {
    final labels = [for (final p in series) p.label];
    final maxY = [
      for (final line in lines) ...line.values,
      1.0,
    ].reduce((a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.1,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, _) => Text(
                isMoney ? formatRs(value.toInt()) : '${value.toInt()}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (series.length / 4).ceilToDouble().clamp(1, 31),
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(labels[i],
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          for (final line in lines)
            LineChartBarData(
              spots: [
                for (var i = 0; i < line.values.length; i++)
                  FlSpot(i.toDouble(), line.values[i]),
              ],
              isCurved: true,
              color: line.color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${labels[spot.x.toInt()]}\n${lines[spot.barIndex].label}: '
                  '${isMoney ? formatRs(spot.y.toInt()) : spot.y.toInt()}',
                  const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trend block on the Reports screen: each KPI's current
/// total vs the immediately preceding equal-length period.
class AdminReportTrendSection extends StatelessWidget {
  const AdminReportTrendSection({
    super.key,
    required this.current,
    required this.previous,
  });

  final AdminReport current;
  final AdminReport previous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.admin2_reportsTrendTitle,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        AdminReportTrend(
            label: l10n.admin2_reportsBookings,
            current: current.totalBookings,
            previous: previous.totalBookings),
        AdminReportTrend(
            label: l10n.admin2_reportsRevenue,
            current: current.bookingRevenue,
            previous: previous.bookingRevenue,
            isMoney: true),
        AdminReportTrend(
            label: l10n.admin2_reportsIncome,
            current: current.financeIncome,
            previous: previous.financeIncome,
            isMoney: true),
        AdminReportTrend(
            label: l10n.admin2_reportsExpense,
            current: current.financeExpense,
            previous: previous.financeExpense,
            isMoney: true),
      ],
    );
  }
}

/// One trend line: a KPI's current total vs the immediately
/// preceding equal-length period, as "12 (▲ 20% vs previous
/// period)" — or "no previous data" when the previous total is 0.
class AdminReportTrend extends StatelessWidget {
  const AdminReportTrend({
    super.key,
    required this.label,
    required this.current,
    required this.previous,
    this.isMoney = false,
  });

  final String label;
  final int current;
  final int previous;
  final bool isMoney;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pct = trendPercent(current: current, previous: previous);
    final valueText = isMoney
        ? l10n.amountRs(formatRs(current))
        : '$current';
    final trendText = pct == null
        ? l10n.admin2_reportsTrendNoPrevious
        : l10n.admin2_reportsTrend(pct >= 0 ? '+' : '',
            pct.toStringAsFixed(0));
    final up = (pct ?? 0) >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $valueText ($trendText)',
        style: TextStyle(
          fontSize: 12,
          color: pct == null
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : up
                  ? Colors.green.shade700
                  : Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
