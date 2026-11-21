import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'customer_kyc_slots.dart';

/// Walk-in CRM: the derived statuses for the detail screen,
/// computed from the record + the shop's bookings for the
/// customer (already loaded by the detail view, newest first).
/// Dormant is "no booking in 90 days" — the last activity is the
/// newest booking's pickup, or the record's creation when the
/// customer has never booked. Frequent is 2+ rentals (the same
/// threshold as the list's Regular badge).
({
  String shopStatus,
  bool kycIncomplete,
  bool dormant,
  bool frequent,
}) derivedCustomerStatuses({
  required CustomerEntity customer,
  required List<BookingEntity> bookings,
  required String shopId,
}) {
  final lastActivity = bookings.isNotEmpty
      ? bookings.first.pickupTime
      : customer.createdAt;
  return (
    shopStatus: customer.statusForShop(shopId),
    kycIncomplete: !isKycCompleteForEntity(customer),
    dormant: DateTime.now().difference(lastActivity).inDays > 90,
    frequent: bookings.length >= 2,
  );
}
