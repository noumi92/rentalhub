import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Phase A (A1): route-level loaders for routes that take an id.
///
/// A route such as `/owner/handover/:id` cannot build its view directly —
/// the view needs a [BookingEntity], not an id. These loaders fetch the
/// entity from Firestore (via the existing remote data sources), show a
/// loading state while fetching, and show an honest not-found screen when
/// the id does not exist, instead of crashing or showing mock data.
class BookingRouteLoader extends StatelessWidget {
  const BookingRouteLoader({
    super.key,
    required this.bookingId,
    required this.builder,
  });

  final String bookingId;
  final Widget Function(BuildContext context, BookingEntity booking) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookingEntity?>(
      future: sl<BookingRemoteDataSource>().getBookingById(bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final booking = snapshot.data;
        if (booking == null) {
          return RouteNotFoundScreen(
            message: 'Booking $bookingId was not found.',
          );
        }
        return builder(context, booking);
      },
    );
  }
}

/// Same idea for `/owner/rates/:vehicleId`. There is no getVehicleById in
/// the fleet data source, so the shop's vehicles are listed and the one
/// with the matching id is picked (small data set; B1 adds a direct fetch).
class VehicleRouteLoader extends StatelessWidget {
  const VehicleRouteLoader({
    super.key,
    required this.vehicleId,
    required this.shopId,
    required this.builder,
  });

  final String vehicleId;
  final String shopId;
  final Widget Function(BuildContext context, VehicleEntity vehicle) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VehicleEntity>>(
      future: sl<FleetRemoteDataSource>().getShopVehicles(shopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final vehicles = snapshot.data ?? const <VehicleEntity>[];
        VehicleEntity? vehicle;
        for (final v in vehicles) {
          if (v.vehicleId == vehicleId) {
            vehicle = v;
            break;
          }
        }
        if (vehicle == null) {
          return RouteNotFoundScreen(
            message: 'Vehicle $vehicleId was not found.',
          );
        }
        return builder(context, vehicle);
      },
    );
  }
}

class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 52,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
