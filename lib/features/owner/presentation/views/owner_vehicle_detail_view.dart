import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/live_booking_stream.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/vehicle_detail/vehicle_detail_bookings.dart';
import '../widgets/vehicle_detail/vehicle_detail_feature_actions.dart';
import '../widgets/vehicle_detail/vehicle_detail_photo_card.dart';
import '../widgets/vehicle_detail/vehicle_detail_rates_grid.dart';

/// Audit §5 (item 15): the OWNER vehicle-detail screen — the fleet
/// card used to open the customer detail route. Photo, identity,
/// specs, rates summary, the vehicle's bookings, and the owner
/// actions: Manage rates, Booking calendar, and Edit. Edit opens the
/// car-details editor (ownerEditVehicle); Manage rates opens the
/// per-package rates editor.
///
/// Showroom redesign (Phase 2, 2026-11-16): the sticky bottom bar is
/// DELETED — its three actions are relocated inline, so no action is
/// lost: Booking calendar, Edit Vehicle and Manage rates sit in ONE
/// icon-over-label tile row below the spec chips (phone-test build
/// 80 — they were split across the chips row and the Rates header).
/// The 7 rate tiers render in a 2-column grid. The navy AppBar with
/// the green PK plate badge, the rounded photo card and all 5 spec
/// chips (the guide shows 4; colour is the 5th — kept) stay exactly
/// as they were.
class OwnerVehicleDetailView extends StatefulWidget {
  final VehicleEntity vehicle;

  /// Bookings for tests / embeds. When null they are loaded lazily
  /// from Firestore; any load failure renders the honest empty state.
  final List<BookingEntity>? bookings;
  final VoidCallback? onBack;

  const OwnerVehicleDetailView({
    super.key,
    required this.vehicle,
    this.bookings,
    this.onBack,
  });

  @override
  State<OwnerVehicleDetailView> createState() => _OwnerVehicleDetailViewState();
}

class _OwnerVehicleDetailViewState extends State<OwnerVehicleDetailView> {
  List<BookingEntity>? _bookings;
  bool _loading = false;
  // Live updates (Item 2): the subscription behind the bookings
  // section. A view given explicit `bookings` (tests / embeds)
  // never subscribes.
  StreamSubscription<List<BookingEntity>>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    if (widget.bookings != null) {
      _bookings = widget.bookings;
    } else {
      _loadBookings();
    }
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  /// Live updates (Item 2): the vehicle's bookings follow their stream — a submit or status change updates this screen while it is open, instead of the single load at open time.
  Future<void> _loadBookings() async {
    await _bookingsSub?.cancel();
    setState(() => _loading = true);
    _bookingsSub = subscribeLiveBookings((ds) => ds.streamVehicleBookings(widget.vehicle.vehicleId), (list) {
      if (mounted) setState(() { _bookings = list; _loading = false; });
    }, onError: () {
      if (mounted) setState(() => _bookings = const []);
    });
    if (_bookingsSub == null && mounted) setState(() => _bookings = const []);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = widget.vehicle;
    final bookings = _bookings ?? const <BookingEntity>[];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: v.displayName, subtitle: v.plateNumber, onBack: widget.onBack ?? () => context.pop(), actions: [Padding(padding: const EdgeInsets.only(right: 12), child: PakistaniPlateWidget(plateNumber: v.plateNumber, isCompact: true))]),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VehicleDetailPhotoCard(vehicle: v),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [_specChip(context, v.color ?? '—'), _specChip(context, l10n.vehicleDetailSeats(v.seats)), _specChip(context, v.fuelType), _specChip(context, v.transmission), _specChip(context, v.category)],
                          ),
                          const SizedBox(height: 18),
                          // Phone-test build 80: all three feature
                          // actions in ONE icon-over-label tile row
                          // below the chips (was: calendar + Edit
                          // here, Manage rates as a pill in the
                          // Rates header). Edit stays the filled
                          // primary (white on orangeFill 5.18:1).
                          VehicleDetailFeatureActions(
                            onCalendar: () => context.push(RouteNames.ownerCalendar.replaceFirst(':vehicleId', v.vehicleId)),
                            onEdit: () => context.push(RouteNames.ownerEditVehicle.replaceFirst(':id', v.vehicleId)),
                            onManageRates: () => context.push(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)),
                          ),
                          const SizedBox(height: 18),
                          VehicleDetailRatesGrid(
                            vehicle: v,
                            onFareTable: () => context.push(RouteNames.ownerFareTable.replaceFirst(':vehicleId', v.vehicleId)),
                            onEstimate: () => context.push(RouteNames.ownerPriceEstimate.replaceFirst(':vehicleId', v.vehicleId)),
                          ),
                          const SizedBox(height: 18),
                          VehicleDetailBookings(bookings: bookings, loading: _loading),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Phase 2: the sticky bottom bar is DELETED — its three
            // actions (Manage rates / Booking calendar / Edit) are
            // exactly the ones relocated inline above (rates header
            // pill + the action row below the spec chips). No action
            // is lost, so there is no bar to render here.
          ],
        ),
      ),
    );
  }

  Widget _specChip(BuildContext context, String label) {
    return Chip(label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)));
  }
}
