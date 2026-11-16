import '../../../../bookings/domain/entities/booking_entity.dart';

/// Team B (UI/UX audit 2026-11-15, FG-1): the owner dashboard's
/// booking-derived numbers, extracted from [OwnerDashboardView] so
/// the view stays under the 250-line cap. Pure functions over the
/// live bookings list — same definitions the view used inline
/// (revenue = completed / active / paid bookings by pickup date).

bool _isRevenue(BookingEntity b) =>
    b.status == 'completed' || b.status == 'active' || b.status == 'paid';

int totalRevenue(List<BookingEntity> bookings) => bookings
    .where(_isRevenue)
    .fold(0, (total, b) => total + b.totalAmount);

int todayEarnings(List<BookingEntity> bookings) {
  final now = DateTime.now();
  return bookings
      .where((b) =>
          _isRevenue(b) &&
          b.pickupTime.year == now.year &&
          b.pickupTime.month == now.month &&
          b.pickupTime.day == now.day)
      .fold(0, (total, b) => total + b.totalAmount);
}

int _monthRevenue(List<BookingEntity> bookings, int year, int month) =>
    bookings
        .where((b) =>
            _isRevenue(b) &&
            b.pickupTime.year == year &&
            b.pickupTime.month == month)
        .fold(0, (total, b) => total + b.totalAmount);

/// Phase 1 showroom redesign: the dashboard's Monthly Revenue is
/// the CURRENT calendar month's revenue (by pickup date) — the old
/// "Gross Revenue (This Month)" label displayed the all-time total
/// ([totalRevenue]) under a monthly name. This is the real month
/// figure; [growthPct] compares it with last month.
int monthRevenue(List<BookingEntity> bookings) {
  final now = DateTime.now();
  return _monthRevenue(bookings, now.year, now.month);
}

int? growthPct(List<BookingEntity> bookings) {
  final now = DateTime.now();
  final thisMonth = monthRevenue(bookings);
  final lastMonthDate = DateTime(now.year, now.month - 1);
  final lastMonth =
      _monthRevenue(bookings, lastMonthDate.year, lastMonthDate.month);
  if (lastMonth == 0) return null;
  return ((thisMonth - lastMonth) / lastMonth * 100).round();
}

/// The 8 most recent bookings by pickup time, for the ledger.
List<BookingEntity> ledgerFor(List<BookingEntity> bookings) =>
    (List<BookingEntity>.of(bookings)
          ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime)))
        .take(8)
        .toList();
