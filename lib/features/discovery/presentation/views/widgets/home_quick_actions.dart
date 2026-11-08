import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/quick_action_tiles.dart';
import '../../cubit/discovery_cubit.dart';
import '../../../../../l10n/app_localizations.dart';

/// E1: the customer Home quick actions, built on [QuickActionTiles].
///
/// Destinations (all real, no dead tiles):
/// - Book a Car → the full-screen map ([RouteNames.customerHomeMap]):
///   the shop list is already on this screen, so "book a car" means
///   browse the map, tap a shop, then its cars — the real booking
///   entry, not a no-op scroll.
/// - My Reservations → the bookings list ([RouteNames.customerBookings]):
///   the pickup-pass route needs a booking id, and the list is where
///   a paid/active booking's l10n.bookingsViewPass lives ("Scan Pass"
///   stays reachable there, it just stops being a Home tile).
/// - Nearby Shops → flips this screen's own list/map switch
///   ([DiscoveryCubit.toggleMapView]) to the inline map of nearby
///   shops, instead of leaving Home like Book a Car does.
/// - SOS → the SOS screen ([RouteNames.customerSos]).
class CustomerHomeQuickActions extends StatelessWidget {
  const CustomerHomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return QuickActionTiles(
      tiles: [
        QuickActionTile(
          icon: Icons.directions_car_rounded,
          label: l10n.quickBookCar,
          color: AppColors.secondary,
          onTap: () => context.push(RouteNames.customerHomeMap),
        ),
        QuickActionTile(
          icon: Icons.calendar_month_rounded,
          label: l10n.quickMyReservations,
          color: AppColors.primary,
          onTap: () => context.go(RouteNames.customerBookings),
        ),
        QuickActionTile(
          icon: Icons.storefront_rounded,
          label: l10n.quickNearbyShops,
          color: AppColors.accentSuccess,
          onTap: () => context.read<DiscoveryCubit>().toggleMapView(true),
        ),
        QuickActionTile(
          icon: Icons.sos_rounded,
          label: l10n.sos,
          color: AppColors.accentDanger,
          onTap: () => context.push(RouteNames.customerSos),
        ),
      ],
    );
  }
}
