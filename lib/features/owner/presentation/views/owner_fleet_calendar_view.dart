import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Audit §5 (O31): the multi-car fleet calendar — one month grid with
/// a per-car availability bar for every fleet vehicle (Booked /
/// Available legend), where the existing per-vehicle calendar stays
/// the drill-down: tapping a car opens its own calendar. Loads are
/// lazy (try/catch): any failure renders an empty fleet + error
/// state with retry instead of a spinner that never resolves.
class OwnerFleetCalendarView extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerFleetCalendarView({super.key, this.onBack});

  @override
  State<OwnerFleetCalendarView> createState() => _OwnerFleetCalendarViewState();
}

class _OwnerFleetCalendarViewState extends State<OwnerFleetCalendarView> {
  List<VehicleEntity> _fleet = [];
  List<BookingEntity> _bookings = [];
  bool _loading = true;
  bool _hasError = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  // Live updates (Item 2): the subscription behind the booked-day
  // bars. The fleet list itself stays a one-time load (re-run by
  // the error-state retry).
  StreamSubscription<List<BookingEntity>>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final shopId = currentShopId();
      final fleet = await sl<FleetRemoteDataSource>().getShopVehicles(shopId);
      if (!mounted) return;
      setState(() {
        _fleet = fleet;
        _loading = false;
      });
      // Live updates (Item 2): a submit or status change repaints
      // the booked days while the calendar is open.
      _subscribeBookings(shopId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  void _subscribeBookings(String shopId) {
    if (_bookingsSub != null) return;
    try {
      _bookingsSub =
          sl<BookingRemoteDataSource>().streamShopBookings(shopId).listen(
        (list) {
          if (mounted) setState(() => _bookings = list);
        },
        onError: (_) {
          // Booked days keep their last good state; the fleet load
          // above still owns the error state.
        },
      );
    } catch (_) {}
  }

  bool _isBooked(String vehicleId, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _bookings.any((b) {
      if (b.vehicleId != vehicleId) return false;
      // OW-m33: 'requested' is a pending ask, not a booking —
      // it used to paint the car red before anyone approved it.
      if (b.status == 'rejected' || b.status == 'cancelled' || b.status == 'requested') return false;
      final from = DateTime(b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
      final to = DateTime(b.returnTime.year, b.returnTime.month, b.returnTime.day);
      return !d.isBefore(from) && !d.isAfter(to);
    });
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month && day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final monthLabel = DateFormat('MMMM yyyy').format(_month);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.fleetCalendarTitle,
              subtitle: monthLabel,
              onBack: widget.onBack ?? () => context.pop(),
              actions: [
                // OW-m33: jump back to the current month.
                TextButton(onPressed: () => setState(() => _month = DateTime(DateTime.now().year, DateTime.now().month)), child: Text(l10n.dashboardToday, style: const TextStyle(color: Colors.white))),
                IconButton(icon: const Icon(Icons.chevron_left_rounded, color: Colors.white), tooltip: l10n.fleetCalendarPrevMonth, onPressed: () => _shiftMonth(-1)),
                IconButton(icon: const Icon(Icons.chevron_right_rounded, color: Colors.white), tooltip: l10n.fleetCalendarNextMonth, onPressed: () => _shiftMonth(1)),
              ],
            ),
            Expanded(
              child: _loading
                  ? AppLoadingState(message: l10n.fleetCalendarTitle)
                  : _hasError
                      ? AppErrorState(message: l10n.fleetCalendarLoadError, onRetry: _load)
                      : _fleet.isEmpty
                          ? AppEmptyState(title: l10n.fleetCalendarEmptyTitle, message: l10n.fleetCalendarEmptyMessage, icon: Icons.no_crash_rounded)
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceEvenly,
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _legend(context, AppColors.errorContainerFor(Theme.of(context).brightness), l10n.fleetCalendarBooked),
                                    _legend(context, AppColors.successContainerFor(Theme.of(context).brightness), l10n.fleetCalendarAvailable),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._fleet.map((v) => Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                        onTap: () => context.push(RouteNames.ownerCalendar.replaceFirst(':vehicleId', v.vehicleId)),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(child: Text(v.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                                                  Text(v.plateNumber, style: Theme.of(context).textTheme.labelMedium),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              // One segment per day of the
                                              // month: booked = red, else green.
                                              Row(
                                                children: [
                                                  for (int day = 1; day <= daysInMonth; day++)
                                                    Expanded(
                                                      child: Container(
                                                        height: 18,
                                                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                                        decoration: BoxDecoration(
                                                          color: _isBooked(v.vehicleId, DateTime(_month.year, _month.month, day)) ? AppColors.errorContainerFor(Theme.of(context).brightness) : AppColors.successContainerFor(Theme.of(context).brightness),
                                                          borderRadius: BorderRadius.circular(2),
                                                          // OW-m33: a ring on today so the owner can
                                                          // find the current day at a glance.
                                                          border: _isToday(day) ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5) : null,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String label) {
    final brightness = Theme.of(context).brightness;
    // OW-m33: the pale swatches were indistinguishable at a
    // glance — a matching border + a bold label tell them apart.
    final border = color == AppColors.errorContainerFor(brightness)
        ? AppColors.errorOnContainerFor(brightness)
        : AppColors.successBorderFor(brightness);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: border, width: 1.5))),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
