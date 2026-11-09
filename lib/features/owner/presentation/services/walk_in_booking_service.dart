import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../customer/utils/save_walk_in_customer.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/guarantor_picker.dart';
import '../widgets/manual_booking_package_selector.dart';

/// Phase B (D2): the walk-in booking flow, extracted from
/// [OwnerManualBookingView] so the view stays under the 250-line
/// cap. Creates the booking, saves the customer record, and records
/// the advance received at the counter. Throws on failure; the caller
/// shows it.
///
/// Audit §5 item 1 (O16/O17): a walk-in is NO LONGER instantly paid.
/// The booking is `paid` only when the received advance covers the
/// required advance; anything less (including 0) leaves it `approved`
/// with the remaining balance still due.
class WalkInBookingService {
  /// Phase B (D2): a blacklisted CNIC cannot book at the counter
  /// either. Throws when the lookup itself fails (Firestore
  /// unreachable) — the caller refuses the booking with an error
  /// instead of proceeding unchecked or crashing on an unhandled
  /// async error. The save-side check in [saveWalkInCustomer] is
  /// only a backstop: the booking service swallows save errors by
  /// design, so this pre-submit check is the block that actually
  /// stops a blacklisted walk-in.
  static Future<bool> isCnicBlacklisted(String cnic) =>
      sl<BlacklistRemoteDataSource>().isCnicBlacklisted(cnic);

  static Future<BookingEntity> createWalkInBooking({
    required String name,
    required String phone,
    required String cnic,
    required GuarantorSelection? guarantor,
    required VehicleEntity vehicle,
    required VehiclePackageEntity package,
    required bool isWithDriver,
    required int rentAmount,
    required int advanceRequired,
    DateTime? pickupTime,
    DateTime? returnTime,
    String tripType = 'in_city',
    int advanceReceived = 0,
  }) async {
    final ds = sl<BookingRemoteDataSource>();
    final pickup = pickupTime ?? DateTime.now();
    final ret = returnTime ??
        ManualBookingPackageSelector.returnTimeFor(
          pickup: pickup,
          package: package,
        );
    final booking = await ds.createBookingRequest(
      customerId: 'walkin-${DateTime.now().millisecondsSinceEpoch}',
      shopId: currentShopId(),
      vehicleId: vehicle.vehicleId,
      vehicleName: '${vehicle.make} ${vehicle.model}',
      customerName: name,
      customerPhone: phone,
      customerCnic: cnic,
      guarantorName: guarantor?.name,
      guarantorCnic: guarantor?.cnic,
      guarantorPhone: guarantor?.phone,
      packageType: package.label,
      isWithDriver: isWithDriver,
      pickupTime: pickup,
      returnTime: ret,
      totalAmount: rentAmount,
      advanceRequired: advanceRequired,
      tripType: tripType,
    );

    // Phase B (C1): the walk-in customer is saved with their CNIC,
    // so they show up in the customers list. A failed save must
    // never fail the booking itself.
    try {
      await saveWalkInCustomer(
        shopId: currentShopId(),
        name: name,
        phone: phone,
        cnic: cnic,
        fallbackCustomerId: booking.customerId,
      );
    } catch (_) {}

    // Audit §5 item 1: the counter advance decides the status — a
    // full advance pays the booking, anything less approves it with
    // the balance still due.
    if (advanceReceived >= advanceRequired && advanceRequired > 0) {
      return ds.verifyPayment(
          bookingId: booking.bookingId, advanceAmount: advanceReceived);
    }
    return ds.recordAdvancePayment(
        bookingId: booking.bookingId, advanceAmount: advanceReceived);
  }
}
