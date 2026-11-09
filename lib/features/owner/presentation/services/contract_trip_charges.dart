import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Gap (a): the trip charges the agreement PDF prints for an
/// out-of-city trip — resolved at the signing point, from the
/// vehicle's own stored rates.
///
/// The rule, deliberately conservative for a legal document:
/// - Vehicle loaded → the booking's trip type plus the vehicle's
///   ACTUAL `driverNightStayPkr` / `tollsPaidBy`. A null per-night
///   rate means the owner never set one, so the generator's deck
///   default (Rs 2,000) applies — never a custom rate the owner set,
///   because the loaded vehicle carries it.
/// - Vehicle missing (lookup failed / DI unavailable / deleted) →
///   everything null. The generator omits the night-stay and tolls
///   lines entirely for a null trip type, instead of printing the
///   Rs 2,000 default or a guessed tolls note. The caller must pass
///   these nulls through as-is — never substitute defaults here.
({String? tripType, int? driverNightStayPkr, String? tollsPaidBy})
    resolvePdfTripCharges({
  required BookingEntity booking,
  required VehicleEntity? vehicle,
}) {
  if (vehicle == null) {
    return (
      tripType: null,
      driverNightStayPkr: null,
      tollsPaidBy: null,
    );
  }
  return (
    tripType: booking.tripType,
    driverNightStayPkr: vehicle.driverNightStayPkr,
    tollsPaidBy: vehicle.tollsPaidBy,
  );
}
