import '../domain/entities/booking_entity.dart';

/// Phase B (B3): shared availability rules for the booking calendar
/// and the package picker. A day is blocked when a booking that is
/// not cancelled or rejected covers it. Paid and active bookings are
/// confirmed; requested / payment-submitted / approved bookings are
/// still pending but block the day too, so the car is never double
/// booked while a request is in flight. A `disputed` booking still
/// blocks the day — the car is not free while its dispute is open.
const Set<String> kBlockingBookingStatuses = {
  'requested',
  'approved',
  'payment_submitted',
  'paid',
  'active',
  'disputed',
};

bool isDayBlocked(List<BookingEntity> bookings, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return bookings.any((b) {
    if (!kBlockingBookingStatuses.contains(b.status)) return false;
    final from = DateTime(
        b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
    final to =
        DateTime(b.returnTime.year, b.returnTime.month, b.returnTime.day);
    return !d.isBefore(from) && !d.isAfter(to);
  });
}

bool isDayConfirmed(List<BookingEntity> bookings, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return bookings.any((b) {
    if (b.status != 'paid' && b.status != 'active') return false;
    final from = DateTime(
        b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
    final to =
        DateTime(b.returnTime.year, b.returnTime.month, b.returnTime.day);
    return !d.isBefore(from) && !d.isAfter(to);
  });
}

Set<DateTime> blockedDaysOf(List<BookingEntity> bookings) {
  final days = <DateTime>{};
  for (final b in bookings) {
    if (!kBlockingBookingStatuses.contains(b.status)) continue;
    var d = DateTime(
        b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
    final to =
        DateTime(b.returnTime.year, b.returnTime.month, b.returnTime.day);
    while (!d.isAfter(to)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
  }
  return days;
}
