import '../../../core/di/injection_container.dart';
import '../data/datasources/booking_remote_data_source.dart';
import '../../fleet/domain/entities/fixed_route_entity.dart';
import '../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import 'booking_availability.dart';

/// Phase B (B3): the availability data the booking picker loads when
/// a vehicle is supplied — the car's blocked days and the shop's
/// enabled fixed routes. Extracted from [RentPackagePickerView] so
/// the view stays under the 250-line cap. Both loads are skipped
/// when DI is not initialised (legacy callers and unit tests).
Future<({Set<DateTime> blockedDays, List<FixedRouteEntity> routes})>
    loadPickerAvailability({
  required String vehicleId,
  required String shopId,
}) async {
  var blockedDays = <DateTime>{};
  var routes = <FixedRouteEntity>[];
  if (sl.isRegistered<BookingRemoteDataSource>()) {
    final bookings =
        await sl<BookingRemoteDataSource>().getVehicleBookings(vehicleId);
    blockedDays = blockedDaysOf(bookings);
  }
  if (sl.isRegistered<GetShopFixedRoutesUseCase>()) {
    final all = await sl<GetShopFixedRoutesUseCase>()(shopId);
    routes = all.where((r) => r.enabled).toList();
  }
  return (blockedDays: blockedDays, routes: routes);
}
