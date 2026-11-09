import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Audit §5 (item 15): the OWNER vehicle-detail screen — the fleet
/// card used to open the customer detail route. Photo, identity,
/// specs, rates summary, the vehicle's bookings, and the owner
/// actions: Manage rates, Booking calendar, and Edit. Edit opens the
/// rate matrix: it is the only vehicle editor that exists today
/// (there is no specs/photos edit screen), so it is the honest
/// destination for the button until one is built.
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

  @override
  void initState() {
    super.initState();
    if (widget.bookings != null) {
      _bookings = widget.bookings;
    } else {
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      final list = await sl<BookingRemoteDataSource>().getVehicleBookings(widget.vehicle.vehicleId);
      if (mounted) setState(() => _bookings = list);
    } catch (_) {
      if (mounted) setState(() => _bookings = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    final isAvailable = v.status == 'available';
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: v.displayName,
              subtitle: v.plateNumber,
              onBack: widget.onBack ?? () => context.pop(),
              actions: [Padding(padding: const EdgeInsets.only(right: 12), child: PakistaniPlateWidget(plateNumber: v.plateNumber, isCompact: true))],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)), child: _photo(v)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(l10n.vehicleDetailDailyRate(l10n.amountRs(formatRs(v.rates.daily24))), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: isAvailable ? AppColors.accentSuccessStrong : AppColors.orangeFill, borderRadius: BorderRadius.circular(10)),
                                child: Text(isAvailable ? l10n.available : l10n.fleetOnRent, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _specChip(context, v.color ?? '—'),
                              _specChip(context, l10n.vehicleDetailSeats(v.seats)),
                              _specChip(context, v.fuelType),
                              _specChip(context, v.transmission),
                              _specChip(context, v.category),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(l10n.vehicleDetailRatesTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          ...v.effectivePackages.map((p) => _rateRow(context, p.label, l10n.amountRs(formatRs(p.pricePkr)))),
                          if (v.securityDepositPkr != null) _rateRow(context, l10n.vehicleDetailDeposit, l10n.amountRs(formatRs(v.securityDepositPkr!))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.table_rows_rounded, size: 18), label: Text(l10n.vehicleDetailFareTable), onPressed: () => context.push(RouteNames.ownerFareTable.replaceFirst(':vehicleId', v.vehicleId)))),
                              const SizedBox(width: 8),
                              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.calculate_outlined, size: 18), label: Text(l10n.ratesViewEstimate), onPressed: () => context.push(RouteNames.ownerPriceEstimate.replaceFirst(':vehicleId', v.vehicleId)))),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(l10n.vehicleDetailBookingsTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          if (_loading)
                            AppLoadingState(message: l10n.vehicleDetailBookingsTitle)
                          else if (bookings.isEmpty)
                            Text(l10n.vehicleDetailNoBookings, style: Theme.of(context).textTheme.bodyMedium)
                          else
                            ...bookings.map((b) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(b.customerName ?? b.customerId, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text('${b.packageType} • ${DateFormat('d MMM, h:mm a').format(b.pickupTime)} → ${DateFormat('d MMM, h:mm a').format(b.returnTime)}'),
                                    trailing: Chip(label: Text(b.status, style: Theme.of(context).textTheme.labelSmall)),
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
                  Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.tune_rounded, size: 18), label: Text(l10n.vehicleDetailManageRates), onPressed: () => context.push(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.calendar_month_rounded, size: 18), label: Text(l10n.vehicleDetailCalendar), onPressed: () => context.push(RouteNames.ownerCalendar.replaceFirst(':vehicleId', v.vehicleId)))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(icon: const Icon(Icons.edit_rounded, size: 18), label: Text(l10n.vehicleDetailEdit), onPressed: () => context.push(RouteNames.ownerRatesVehicle.replaceFirst(':vehicleId', v.vehicleId)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specChip(BuildContext context, String label) {
    return Chip(label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)));
  }

  Widget _rateRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 8),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
