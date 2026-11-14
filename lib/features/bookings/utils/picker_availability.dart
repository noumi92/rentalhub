import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/di/injection_container.dart';
import '../data/datasources/booking_remote_data_source.dart';
import '../domain/entities/booking_entity.dart';
import '../../fleet/domain/entities/fixed_route_entity.dart';
import '../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import 'booking_availability.dart';
import 'live_booking_stream.dart';

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

/// Live updates (Item 2): the booking picker's availability feed —
/// the car's blocked days and the shop's enabled fixed routes, kept
/// live while the picker is open. [load] runs the one-time load for
/// the first paint (and the routes, which have no live feed) and
/// then follows the vehicle's bookings stream, so a booking
/// submitted elsewhere blocks its days here without reopening.
/// [onChanged] fires after every load or emission; the owner
/// (the picker view) guards it with its mounted check.
class PickerAvailabilityFeed {
  PickerAvailabilityFeed({
    required this.vehicleId,
    required this.shopId,
    required this.onChanged,
  });

  final String vehicleId;
  final String shopId;
  final VoidCallback onChanged;

  Set<DateTime> blockedDays = {};
  List<FixedRouteEntity> routes = [];
  StreamSubscription<List<BookingEntity>>? _sub;

  void load() {
    if (sl.isRegistered<BookingRemoteDataSource>() ||
        sl.isRegistered<GetShopFixedRoutesUseCase>()) {
      loadPickerAvailability(vehicleId: vehicleId, shopId: shopId)
          .then((data) {
        blockedDays = data.blockedDays;
        routes = data.routes;
        onChanged();
      });
    }
    if (sl.isRegistered<BookingRemoteDataSource>()) {
      _sub = subscribeLiveBookings(
        (ds) => ds.streamVehicleBookings(vehicleId),
        (bookings) {
          blockedDays = blockedDaysOf(bookings);
          onChanged();
        },
      );
    }
  }

  void dispose() => _sub?.cancel();
}
