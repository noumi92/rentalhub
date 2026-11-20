import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../customer/utils/save_walk_in_customer.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
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
    FixedRouteEntity? fixedRoute,
    int advanceReceived = 0,
    // Walk-in rework (O21–O24): a REGISTERED customer's real id.
    // Null keeps the legacy path — a synthetic 'walkin-…' id plus a
    // saved walk-in customer record — so older callers still work.
    String? customerId,
    // Step 3: the deposit actually received (null = not received)
    // and the counter discount (null/0 = none). Both are stored on
    // the booking; the booked total in [rentAmount] is already net
    // of the discount.
    double? depositAmountPkr,
    double? discountAmountPkr,
  }) async {
    final ds = sl<BookingRemoteDataSource>();
    // Shop-id mismatch (2026-11-15, rulebook D12): the booking (and
    // the walk-in customer record below) must carry the shop
    // DOCUMENT id, not the signed-in owner's bare UID — a bare-UID
    // walk-in is invisible to the same owner's triage read, which
    // resolves candidates. The customer flow already writes the
    // document id. A missing/unreachable Firestore resolves to the
    // argument itself, so offline behaviour is unchanged.
    final shopId = await ds.canonicalShopIdFor(currentShopId());
    final pickup = pickupTime ?? DateTime.now();
    final ret = returnTime ??
        ManualBookingPackageSelector.returnTimeFor(
          pickup: pickup,
          package: package,
        );
    final booking = await ds.createBookingRequest(
      customerId:
          customerId ?? 'walkin-${DateTime.now().millisecondsSinceEpoch}',
      shopId: shopId,
      vehicleId: vehicle.vehicleId,
      vehicleName: '${vehicle.make} ${vehicle.model}',
      customerName: name,
      customerPhone: phone,
      customerCnic: cnic,
      guarantorName: guarantor?.name,
      guarantorCnic: guarantor?.cnic,
      guarantorPhone: guarantor?.phone,
      guarantorRelation: guarantor?.relationship,
      origin: 'walk_in',
      packageType: package.label,
      isWithDriver: isWithDriver,
      pickupTime: pickup,
      returnTime: ret,
      totalAmount: rentAmount,
      advanceRequired: advanceRequired,
      tripType: tripType,
      fixedRouteId: fixedRoute?.routeId,
      fixedRouteSummary: fixedRoute?.displayName,
      outCityMode: vehicle.outCityMode,
      outCityPerKmPkr: vehicle.outCityPerKmPkr,
      depositAmountPkr: depositAmountPkr,
      discountAmountPkr: discountAmountPkr,
    );

    // Phase B (C1): an UNREGISTERED walk-in customer is saved with
    // their CNIC, so they show up in the customers list. A registered
    // customer already has a record — nothing is saved here. A failed
    // save must never fail the booking itself.
    if (customerId == null) {
      try {
        await saveWalkInCustomer(
          shopId: shopId,
          name: name,
          phone: phone,
          cnic: cnic,
          fallbackCustomerId: booking.customerId,
        );
      } catch (_) {}
    }
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

  /// O22 "Car is free for this time": true when no live booking for
  /// [vehicleId] overlaps [pickup]–[returnTime]. Only bookings that
  /// still hold the car block it (requested / approved /
  /// payment_submitted / paid / active); cancelled, rejected and
  /// completed ones never do. Pure overlap test, unit-tested.
  static bool bookingOverlaps({
    required DateTime pickup,
    required DateTime returnTime,
    required BookingEntity booking,
  }) {
    if (!_blockingStatuses.contains(booking.status)) return false;
    return booking.pickupTime.isBefore(returnTime) &&
        booking.returnTime.isAfter(pickup);
  }

  static const _blockingStatuses = {
    'requested',
    'approved',
    'payment_submitted',
    'paid',
    'active',
  };

  /// Loads the shop's bookings (or uses [existingBookings] when the
  /// caller already holds them, e.g. widget tests) and reports
  /// whether the car is free for the window. A failed load fails
  /// OPEN — the owner at the counter is never blocked by a read
  /// error; the status badge is the backstop.
  static Future<bool> isVehicleFree({
    required String shopId,
    required String vehicleId,
    required DateTime pickup,
    required DateTime returnTime,
    List<BookingEntity>? existingBookings,
  }) async {
    try {
      final bookings = existingBookings ??
          await sl<BookingRemoteDataSource>().getShopBookings(shopId);
      return !bookings.any((b) =>
          b.vehicleId == vehicleId &&
          bookingOverlaps(
              pickup: pickup, returnTime: returnTime, booking: b));
    } catch (_) {
      return true;
    }
  }
}
