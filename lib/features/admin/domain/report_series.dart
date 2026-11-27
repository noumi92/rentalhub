import '../../bookings/data/models/booking_model.dart';
import '../../finance/data/models/finance_transfer_model.dart';

/// Phase 4 (4.2) — the Reports time series, bucketed client-side
/// from the rows [AdminReport] already fetched (no new server
/// aggregation exists for this; the Firestore SDK's count/sum
/// aggregates cannot produce a per-day series).
///
/// Bucketing: ranges of 62 days or fewer bucket per day, longer
/// ranges per calendar month, so a 30-day range shows 31 daily
/// points and a year shows 12 monthly ones. A booking counts in
/// the bucket of its pickup day; a transfer in the bucket of its
/// creation day. `revenue` is the booked value of the bucket's
/// bookings (completed / active / paid — the same definition as
/// the report KPI, not money received).
class AdminReportPoint {
  const AdminReportPoint({
    required this.bucketStart,
    required this.label,
    required this.bookings,
    required this.revenue,
    required this.income,
    required this.expense,
  });

  /// First day of the bucket (the 1st of the month for monthly
  /// buckets).
  final DateTime bucketStart;

  /// Short axis label, e.g. `12 Jan` (daily) or `Jan 2026`
  /// (monthly). The chart widget localises the month name; this
  /// label is the fallback the series itself carries.
  final String label;
  final int bookings;
  final int revenue;
  final int income;
  final int expense;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

List<AdminReportPoint> buildReportSeries({
  required DateTime from,
  required DateTime to,
  required List<BookingModel> bookings,
  required List<FinanceTransferModel> transfers,
}) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  final monthly = end.difference(start).inDays > 62;
  final buckets = <DateTime, _Bucket>{};
  final keys = <DateTime>[];
  DateTime keyFor(DateTime d) =>
      monthly ? DateTime(d.year, d.month) : DateTime(d.year, d.month, d.day);
  void ensure(DateTime d) {
    final key = keyFor(d);
    if (!buckets.containsKey(key)) {
      buckets[key] = _Bucket();
      keys.add(key);
    }
  }

  // Every bucket in the range exists, even an empty one — the
  // chart line must not jump over a quiet day/month.
  var cursor = keyFor(start);
  final last = keyFor(end);
  while (!cursor.isAfter(last)) {
    ensure(cursor);
    cursor = monthly
        ? DateTime(cursor.year, cursor.month + 1)
        : cursor.add(const Duration(days: 1));
  }
  for (final b in bookings) {
    final day = DateTime(b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
    if (day.isBefore(start) || day.isAfter(end)) continue;
    ensure(b.pickupTime);
    final bucket = buckets[keyFor(b.pickupTime)]!;
    bucket.bookings++;
    if (b.status == 'completed' || b.status == 'active' || b.status == 'paid') {
      bucket.revenue += b.totalAmount;
    }
  }
  for (final t in transfers) {
    final day = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
    if (day.isBefore(start) || day.isAfter(end)) continue;
    ensure(t.createdAt);
    final bucket = buckets[keyFor(t.createdAt)]!;
    if (t.kind == 'income') {
      bucket.income += t.amountPkr;
    } else {
      bucket.expense += t.amountPkr;
    }
  }
  keys.sort();
  return [
    for (final key in keys)
      AdminReportPoint(
        bucketStart: key,
        label: monthly
            ? '${_months[key.month - 1]} ${key.year}'
            : '${key.day} ${_months[key.month - 1]}',
        bookings: buckets[key]!.bookings,
        revenue: buckets[key]!.revenue,
        income: buckets[key]!.income,
        expense: buckets[key]!.expense,
      ),
  ];
}

class _Bucket {
  int bookings = 0;
  int revenue = 0;
  int income = 0;
  int expense = 0;
}

/// Trend of one KPI against the immediately preceding
/// equal-length period, as a percentage change. Null when the
/// previous total is 0 and the current is also 0 (no change to
/// report); +100% when the previous is 0 and the current is not.
double? trendPercent({required int current, required int previous}) {
  if (previous == 0) return current == 0 ? null : 100.0;
  return (current - previous) / previous * 100;
}
