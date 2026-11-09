import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import 'bars_chart_widget.dart';

/// Audit impl (O38): the monthly-earnings bar chart — booking
/// revenue per calendar month for the last 6 months, from paid /
/// active / completed trips only. Extracted from
/// [OwnerReportsView] so the view stays under the 250-line cap.
class ReportEarningsChart extends StatelessWidget {
  final List<BookingEntity> bookings;

  const ReportEarningsChart({super.key, required this.bookings});

  List<(String, int)> get _monthlyBars {
    final now = DateTime.now();
    final bars = <(String, int)>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final revenue = bookings
          .where((b) =>
              (b.status == 'completed' ||
                  b.status == 'paid' ||
                  b.status == 'active') &&
              b.pickupTime.year == month.year &&
              b.pickupTime.month == month.month)
          .fold<int>(0, (total, b) => total + b.totalAmount);
      bars.add((DateFormat('MMM').format(month), revenue));
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bars = _monthlyBars;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.reportEarningsLast6Months,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
        const SizedBox(height: 8),
        BarsChartWidget(
          labels: bars.map((b) => b.$1).toList(),
          values: bars.map((b) => b.$2).toList(),
        ),
      ],
    );
  }
}
