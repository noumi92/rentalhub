import '../../../../bookings/data/datasources/booking_remote_data_source.dart';

/// RQ-F10 (O05/O30): the active booking's return date per vehicle.
/// Extracted from `OwnerFleetView` so the view stays under the
/// 250-line cap (rulebook §2.2).
///
/// Reads the same shop bookings the fleet calendar reads. The active
/// rental is the booking whose window covers now — a future booking
/// is not "on rent" yet; rejected / cancelled / completed bookings
/// never count. When windows overlap, the latest return wins. The
/// result maps vehicle id → return date; a vehicle with no active
/// booking has no entry, so its card shows no return line — never an
/// invented date.
Future<Map<String, DateTime>> loadRentedUntilByVehicle(
  BookingRemoteDataSource ds,
  String shopId,
) async {
  final bookings = await ds.getShopBookings(shopId);
  final now = DateTime.now();
  final map = <String, DateTime>{};
  for (final b in bookings) {
    if (b.status == 'rejected' ||
        b.status == 'cancelled' ||
        b.status == 'completed') {
      continue;
    }
    if (b.pickupTime.isAfter(now) || b.returnTime.isBefore(now)) {
      continue;
    }
    final prev = map[b.vehicleId];
    if (prev == null || b.returnTime.isAfter(prev)) {
      map[b.vehicleId] = b.returnTime;
    }
  }
  return map;
}
