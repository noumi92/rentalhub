import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../widgets/calendar_day_time_grid.dart';
import '../widgets/calendar_month_fleet_grid.dart';
import '../widgets/calendar_week_grid.dart';
import '../widgets/fleet_calendar_legend.dart';

enum _CalendarMode { month, day, week }

/// Audit §5 (O31) + O25: the multi-car fleet calendar. Month is the
/// original per-car availability bar (Booked / Available legend);
/// Day is the spec day view — a 9 AM–9 PM time grid, one row per car,
/// booking blocks coloured Online (navy) vs Walk-in (orange);
/// Week is a 7-day grid of the same per-car rows (tap a day to open
/// it in Day view). Tapping a car still opens its per-vehicle
/// calendar. The grids live in widgets/ so this view stays under the
/// 250-line cap.
///
/// Overlap note: the "blocked automatically" copy is spec text only.
/// The real guarantee today is the vehicle-status lock at booking
/// creation (createBookingLock) — true time-window overlap validation
/// is NOT built; see the O25 report.
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
  _CalendarMode _mode = _CalendarMode.month;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _day = _today();
  DateTime _weekStart = _mondayOf(_today());
  // Live updates (Item 2): the subscription behind the booked-day
  // bars. The fleet list itself stays a one-time load (re-run by
  // the error-state retry).
  StreamSubscription<List<BookingEntity>>? _bookingsSub;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _mondayOf(DateTime day) =>
      day.subtract(Duration(days: day.weekday - 1));

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

  void _shift(int delta) {
    setState(() {
      switch (_mode) {
        case _CalendarMode.month:
          _month = DateTime(_month.year, _month.month + delta);
        case _CalendarMode.day:
          _day = _day.add(Duration(days: delta));
        case _CalendarMode.week:
          _weekStart = _weekStart.add(Duration(days: 7 * delta));
      }
    });
  }

  void _goToday() {
    setState(() {
      _month = DateTime(DateTime.now().year, DateTime.now().month);
      _day = _today();
      _weekStart = _mondayOf(_today());
    });
  }

  String _title(AppLocalizations l10n) => _mode == _CalendarMode.month
      ? l10n.fleetCalendarTitle
      : l10n.calendarTitle;

  String _subtitle(AppLocalizations l10n) {
    switch (_mode) {
      case _CalendarMode.month:
        return DateFormat('MMMM yyyy').format(_month);
      case _CalendarMode.day:
        return DateFormat('EEE, d MMM yyyy').format(_day);
      case _CalendarMode.week:
        final end = _weekStart.add(const Duration(days: 6));
        return '${DateFormat('d MMM').format(_weekStart)} – ${DateFormat('d MMM yyyy').format(end)}';
    }
  }

  String _prevTooltip(AppLocalizations l10n) {
    switch (_mode) {
      case _CalendarMode.month:
        return l10n.fleetCalendarPrevMonth;
      case _CalendarMode.day:
        return l10n.fleetCalendarPrevDay;
      case _CalendarMode.week:
        return l10n.fleetCalendarPrevWeek;
    }
  }

  String _nextTooltip(AppLocalizations l10n) {
    switch (_mode) {
      case _CalendarMode.month:
        return l10n.fleetCalendarNextMonth;
      case _CalendarMode.day:
        return l10n.fleetCalendarNextDay;
      case _CalendarMode.week:
        return l10n.fleetCalendarNextWeek;
    }
  }

  void _openVehicle(VehicleEntity vehicle) => context.push(
      RouteNames.ownerCalendar.replaceFirst(':vehicleId', vehicle.vehicleId));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: _title(l10n),
              subtitle: _subtitle(l10n),
              onBack: widget.onBack ?? () => context.pop(),
              actions: [
                // OW-m33: jump back to the current period.
                TextButton(onPressed: _goToday, child: Text(l10n.dashboardToday, style: const TextStyle(color: Colors.white))),
                IconButton(icon: const Icon(Icons.chevron_left_rounded, color: Colors.white), tooltip: _prevTooltip(l10n), onPressed: () => _shift(-1)),
                IconButton(icon: const Icon(Icons.chevron_right_rounded, color: Colors.white), tooltip: _nextTooltip(l10n), onPressed: () => _shift(1)),
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
                                SegmentedButton<_CalendarMode>(
                                  segments: [
                                    ButtonSegment(value: _CalendarMode.month, label: Text(l10n.fleetCalendarMonth)),
                                    ButtonSegment(value: _CalendarMode.day, label: Text(l10n.fleetCalendarDay)),
                                    ButtonSegment(value: _CalendarMode.week, label: Text(l10n.fleetCalendarWeek)),
                                  ],
                                  selected: {_mode},
                                  onSelectionChanged: (selection) => setState(() => _mode = selection.first),
                                ),
                                const SizedBox(height: 12),
                                FleetCalendarLegend(isMonthMode: _mode == _CalendarMode.month),
                                const SizedBox(height: 12),
                                const FleetCalendarOverlapNote(),
                                const SizedBox(height: 16),
                                switch (_mode) {
                                  _CalendarMode.month => CalendarMonthFleetGrid(month: _month, fleet: _fleet, bookings: _bookings, onVehicleTap: _openVehicle),
                                  _CalendarMode.day => CalendarDayTimeGrid(day: _day, fleet: _fleet, bookings: _bookings, onVehicleTap: _openVehicle),
                                  _CalendarMode.week => CalendarWeekGrid(
                                      weekStart: _weekStart,
                                      fleet: _fleet,
                                      bookings: _bookings,
                                      onDaySelected: (day) => setState(() {
                                        _day = day;
                                        _mode = _CalendarMode.day;
                                      }),
                                      onVehicleTap: _openVehicle,
                                    ),
                                },
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
