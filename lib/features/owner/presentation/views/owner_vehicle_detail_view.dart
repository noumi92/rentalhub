import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../discovery/presentation/views/widgets/vehicle_hero_card.dart'
    show vehicleHeroTag;
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/live_booking_stream.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Audit §5 (item 15): the OWNER vehicle-detail screen — the fleet
/// card used to open the customer detail route. Photo, identity,
/// specs, rates summary, the vehicle's bookings, and the owner
/// actions: Manage rates, Booking calendar, and Edit. Edit opens the
/// car-details editor (ownerEditVehicle); Manage rates opens the
/// per-package rates editor.
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

  String _assetFor(VehicleEntity v) {
    final nameLower = v.displayName.toLowerCase();
    if (nameLower.contains('civic')) return 'assets/images/honda_civic_hero.png';
    if (nameLower.contains('corolla') || nameLower.contains('yaris')) return 'assets/images/toyota_corolla.png';
    return 'assets/images/white_sedan_hero.png';
  }

  Widget _photo(VehicleEntity v) {
    final imageUrl = v.imageUrl;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return Image.network(imageUrl, width: double.infinity, height: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset(_assetFor(v), width: double.infinity, height: 210, fit: BoxFit.cover));
    }
    if (imageUrl != null && (imageUrl.startsWith('/') || imageUrl.contains(r'\'))) {
      return Image.file(File(imageUrl), width: double.infinity, height: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset(_assetFor(v), width: double.infinity, height: 210, fit: BoxFit.cover));
    }
    return Image.asset(_assetFor(v), width: double.infinity, height: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 210));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = widget.vehicle;
    final bookings = _bookings ?? const <BookingEntity>[];
    // OW-M7: the status is mapped explicitly (available / on-rent /
    // maintenance) with the fleet card's label map — the old boolean
    // labelled a maintenance car "On Rent". Maintenance sits on the
    // amber-800 fill (white text ~7.5:1), not the on-rent orange.
    final (statusLabel, statusColor) = v.status == 'available' ? (l10n.available, AppColors.accentSuccessStrong) : v.status == 'maintenance' ? (l10n.fleetFilterMaintenance, AppColors.warningOnContainer) : (l10n.fleetOnRent, AppColors.orangeFill);
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
                    // Header rework (2026-11-09): the rate, the
                    // self-drive badge and the status chip sit ON the
                    // photo over the bottom gradient scrim.
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      child: SizedBox(
                        height: 210,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // OW-m15: the photo carries the fleet
                            // card's hero tag, so the shared-element
                            // transition actually runs.
                            Hero(tag: vehicleHeroTag(v.vehicleId), child: _photo(v)),
                            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0.78)], stops: const [0.30, 0.55, 0.80, 1.0])))),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.fleetDailyRate(formatRs(v.rates.daily24)), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)), child: Text(statusLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white))),
                                      const SizedBox(width: 8),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.65))), child: Text(v.isSelfDriveAvailable ? l10n.selfDriveHyphen : l10n.withDriver, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          Text(l10n.vehicleDetailRatesTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...v.effectivePackages.map((p) => _rateRow(context, p.label, l10n.amountRs(formatRs(p.pricePkr)))),
                          if (v.securityDepositPkr != null) _rateRow(context, l10n.vehicleDetailDeposit, l10n.amountRs(formatRs(v.securityDepositPkr!))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), icon: const Icon(Icons.table_rows_rounded, size: 18), label: Text(l10n.vehicleDetailFareTable), onPressed: () => context.push(RouteNames.ownerFareTable.replaceFirst(':vehicleId', v.vehicleId)))),
                              const SizedBox(width: 8),
                              Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), icon: const Icon(Icons.calculate_outlined, size: 18), label: Text(l10n.ratesViewEstimate), onPressed: () => context.push(RouteNames.ownerPriceEstimate.replaceFirst(':vehicleId', v.vehicleId)))),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(l10n.vehicleDetailBookingsTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (_loading)
                            AppLoadingState(message: l10n.vehicleDetailBookingsTitle)
                          else if (bookings.isEmpty)
                            Text(l10n.vehicleDetailNoBookings, style: Theme.of(context).textTheme.bodyMedium)
                          else
                            ...bookings.map((b) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(b.customerName ?? b.customerId, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('${b.packageType} • ${DateFormat('d MMM, h:mm a').format(b.pickupTime)} → ${DateFormat('d MMM, h:mm a').format(b.returnTime)}'),
                                    // OW-m15: the booking chip is
                                    // coloured by status (was raw text
                                    // on the default chip).
                                    trailing: Chip(label: Text(b.status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)), backgroundColor: _bookingStatusColor(b.status)),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
              child: Row(
                children: [
                  Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), icon: const Icon(Icons.tune_rounded, size: 18), label: Text(l10n.vehicleDetailManageRates), onPressed: () => context.push(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), icon: const Icon(Icons.calendar_month_rounded, size: 18), label: Text(l10n.vehicleDetailCalendar), onPressed: () => context.push(RouteNames.ownerCalendar.replaceFirst(':vehicleId', v.vehicleId)))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size(0, 48)), icon: const Icon(Icons.edit_rounded, size: 18), label: Text(l10n.vehicleDetailEdit), onPressed: () => context.push(RouteNames.ownerEditVehicle.replaceFirst(':id', v.vehicleId)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specChip(BuildContext context, String label) {
    return Chip(label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)));
  }

  Widget _rateRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 8),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Booking-chip fill by status (OW-m15): settled/approved/active
/// green, rejected/cancelled red, everything else (requested, proof
/// submitted) orange. White label text — all three fills are >= 4.5:1.
Color _bookingStatusColor(String status) => switch (status) { 'completed' || 'paid' || 'approved' || 'active' => AppColors.accentSuccessStrong, 'rejected' || 'cancelled' => AppColors.errorDark, _ => AppColors.orangeFill };
