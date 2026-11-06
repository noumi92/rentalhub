import '../../bookings/domain/entities/booking_entity.dart';
import '../domain/entities/customer_entity.dart';

/// Phase B (C1): one row of the owner customers list — a person
/// with their bookings rolled up.
class CustomerSummary {
  final String key;
  final String name;
  final String phone;
  final String? cnic;
  final int bookingCount;
  final int totalSpent;
  final DateTime? lastBookingAt;
  final List<BookingEntity> bookings;
  final CustomerEntity? savedRecord;

  const CustomerSummary({
    required this.key,
    required this.name,
    required this.phone,
    this.cnic,
    required this.bookingCount,
    required this.totalSpent,
    this.lastBookingAt,
    required this.bookings,
    this.savedRecord,
  });

  CustomerSummary copyWith({CustomerEntity? savedRecord}) {
    return CustomerSummary(
      key: key,
      name: name,
      phone: phone,
      cnic: cnic ?? savedRecord?.cnic,
      bookingCount: bookingCount,
      totalSpent: totalSpent,
      lastBookingAt: lastBookingAt,
      bookings: bookings,
      savedRecord: savedRecord ?? this.savedRecord,
    );
  }
}

/// Groups a shop's bookings into one summary per customer. The key
/// is the CNIC when the booking has one, otherwise the customer id —
/// so a walk-in booked under different ids but the same CNIC still
/// rolls up into one row. Saved customer records (OCR, guarantors)
/// without any booking yet are appended as zero-booking rows.
List<CustomerSummary> groupCustomerSummaries({
  required List<BookingEntity> bookings,
  required List<CustomerEntity> savedCustomers,
}) {
  final byKey = <String, List<BookingEntity>>{};
  for (final b in bookings) {
    final key = _keyOf(b);
    byKey.putIfAbsent(key, () => []).add(b);
  }

  final summaries = <CustomerSummary>[];
  for (final entry in byKey.entries) {
    final list = entry.value
      ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
    final first = list.firstWhere(
      (b) => (b.customerName ?? '').isNotEmpty,
      orElse: () => list.first,
    );
    summaries.add(CustomerSummary(
      key: entry.key,
      name: first.customerName ?? 'Customer',
      phone: first.customerPhone ?? '',
      cnic: list
          .map((b) => b.customerCnic)
          .firstWhere((c) => c != null && c.isNotEmpty, orElse: () => null),
      bookingCount: list.length,
      totalSpent: list.fold(0, (sum, b) => sum + b.totalAmount),
      lastBookingAt: list.first.pickupTime,
      bookings: list,
    ));
  }

  for (final saved in savedCustomers) {
    final cnicKey = saved.cnic != null
        ? 'cnic:${saved.cnic!.replaceAll('-', '').trim()}'
        : null;
    final matchIndex = summaries.indexWhere((s) =>
        (cnicKey != null && s.key == cnicKey) ||
        s.key == 'id:${saved.customerId}');
    if (matchIndex != -1) {
      summaries[matchIndex] = summaries[matchIndex].copyWith(
        savedRecord: saved,
      );
    } else {
      summaries.add(CustomerSummary(
        key: cnicKey ?? 'id:${saved.customerId}',
        name: saved.name,
        phone: saved.phone,
        cnic: saved.cnic,
        bookingCount: 0,
        totalSpent: 0,
        lastBookingAt: null,
        bookings: const [],
        savedRecord: saved,
      ));
    }
  }

  summaries.sort((a, b) =>
      (b.lastBookingAt ?? DateTime(2000))
          .compareTo(a.lastBookingAt ?? DateTime(2000)));
  return summaries;
}

String _keyOf(BookingEntity b) {
  final cnic = b.customerCnic?.replaceAll('-', '').trim();
  if (cnic != null && cnic.isNotEmpty) return 'cnic:$cnic';
  return 'id:${b.customerId}';
}
