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
/// cap. Creates the booking, saves the customer record, and marks
/// the cash payment as paid. Throws on failure; the caller shows it.
class WalkInBookingService {
  static Future<BookingEntity> createWalkInBooking({
    required String name,
    required String phone,
    required String cnic,
    required GuarantorSelection? guarantor,
    required VehicleEntity vehicle,
    required VehiclePackageEntity package,
    required bool isWithDriver,
    required int rentAmount,
  }) async {
    final ds = sl<BookingRemoteDataSource>();
    final pickup = DateTime.now();
    final ret = ManualBookingPackageSelector.returnTimeFor(
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
      advanceRequired: rentAmount,
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

    // Walk-in means full cash payment at the counter.
    await ds.verifyPayment(
        bookingId: booking.bookingId, advanceAmount: rentAmount);
    return booking;
  }
}
