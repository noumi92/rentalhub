import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/availability_month_grid.dart';
import '../widgets/calendar_status_chip.dart';

/// Phase B (B3): the booking calendar of one vehicle. Each day shows
/// whether the car is free, has a pending request (amber) or is
/// confirmed out (red). Tapping a day lists that day's bookings.
class OwnerVehicleCalendarView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  const OwnerVehicleCalendarView({
    super.key,
    required this.vehicle,
    this.onBack,
  });

  @override
  State<OwnerVehicleCalendarView> createState() =>
      _OwnerVehicleCalendarViewState();
}

class _OwnerVehicleCalendarViewState extends State<OwnerVehicleCalendarView> {
  List<BookingEntity> _bookings = [];
  bool _loading = true;
  bool _hasError = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }
    // Audit §7 (C4): a failed load used to spin forever — catch it and render an error state with retry, as Fleet does.
    try {
      final bookings = await sl<BookingRemoteDataSource>().getVehicleBookings(widget.vehicle.vehicleId);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  List<BookingEntity> _bookingsOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _bookings.where((b) {
      final from =
          DateTime(b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
      final to =
          DateTime(b.returnTime.year, b.returnTime.month, b.returnTime.day);
      return !d.isBefore(from) && !d.isAfter(to);
    }).toList();
  }

  /// The month grid + legend, shared by the compact stack and the
  /// medium+ side-by-side layout.
  Widget _gridSection() {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        AvailabilityMonthGrid(
          month: _month,
          bookings: _bookings,
          selectedDay: _selectedDay,
          onMonthChanged: (m) => setState(() => _month = m),
          onDaySelected: (d) => setState(() => _selectedDay = d),
        ),
        const SizedBox(height: 12),
        // D3: a Wrap, not a Row — the four legend chips fit on one
        // row on a phone, but at large text scales (and in the wide
        // test font) they flow onto a second row instead of
        // overflowing the 390px viewport.
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 16,
          runSpacing: 8,
          children: [
            _legend(CalendarDayState.free, brightness, l10n.calendarFree),
            _legend(CalendarDayState.requested, brightness, l10n.calendarRequested),
            _legend(CalendarDayState.confirmed, brightness, l10n.calendarConfirmed),
            _legend(CalendarDayState.past, brightness, l10n.calendarPast),
          ],
        ),
      ],
    );
  }

  /// The day-detail agenda. Compact shows today's agenda by default
  /// (audit §7: the old blank space before a day was picked); medium+
  /// always shows the column, with a hint until a day is picked.
  Widget _detailSection({required bool showHint}) {
    final l10n = AppLocalizations.of(context)!;
    // Compact: no selection yet means "today", not blank space.
    final day = _selectedDay ?? (showHint ? null : DateTime.now());
    if (day == null) {
      return Text(l10n.calendarTapDayHint, style: Theme.of(context).textTheme.bodyMedium);
    }
    final selectedBookings = _bookingsOn(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.calendarBookingsOn(day.day, day.month, day.year),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (selectedBookings.isEmpty) Text(l10n.calendarNoBookingsDay),
        ...selectedBookings.map((b) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(b.customerName ?? b.customerId,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              // Audit §7: unambiguous pickup → return date+time
              // (intl `h:mm a`), not "9:05 → 12/11".
              subtitle: Text(
                  '${b.packageType} • ${DateFormat('d MMM, h:mm a').format(b.pickupTime)} → ${DateFormat('d MMM, h:mm a').format(b.returnTime)}'),
              // Round 4: the status chip colours live in
              // CalendarStatusChip — light theme uses an onSurface
              // label + strong border (the light on-container tokens
              // are 2.07–3.44:1 on their containers).
              trailing: CalendarStatusChip(
                  status: b.status, label: _statusLabel(l10n, b.status)),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = widget.vehicle;
    return Scaffold(
      body: SafeArea(
        // C1: MinimalAppBar owns the top inset.
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.calendarTitle,
              subtitle: v.displayName,
              onBack: widget.onBack ?? () => context.pop(),
            ),
            Expanded(
              child: _loading
                  ? AppLoadingState(message: l10n.calendarTitle)
                  : _hasError
                      ? AppErrorState(
                          // No calendar-specific error key exists;
                          // the bookings load error is the same failure.
                          message: l10n.bookingsLoadError,
                          onRetry: _load,
                        )
                      : ListView(
                      padding:
                          const EdgeInsets.all(AppDimensions.paddingVertical),
                      children: [
                        // D3: medium+ puts the month grid beside the
                        // day agenda; compact keeps the stacked
                        // layout exactly as before.
                        if (isMediumOrLarger(context))
                          Row(
                            key: const Key('calendar-two-columns'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _gridSection()),
                              const SizedBox(width: 20),
                              Expanded(
                                  flex: 2,
                                  child: _detailSection(showHint: true)),
                            ],
                          )
                        else ...[
                          _gridSection(),
                          const SizedBox(height: AppDimensions.paddingVertical),
                          _detailSection(showHint: false),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Legend swatches use the grid's own fill + border for the state, so
  // the legend can never drift from the cells (before, both were the
  // bare pale containers with no border — near-invisible on white).
  Widget _legend(CalendarDayState state, Brightness brightness, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: AvailabilityMonthGrid.fillFor(brightness, state),
              borderRadius: BorderRadius.circular(4),
              border: AvailabilityMonthGrid.borderFor(brightness, state)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// The stored status code stays as-is; only the displayed label is
/// localized. Unknown codes fall back to the raw code.
String _statusLabel(AppLocalizations l10n, String status) => {'requested': l10n.requestsStatusRequested, 'payment_submitted': l10n.statusProofSubmitted, 'approved': l10n.statusApproved, 'paid': l10n.statusPaid, 'active': l10n.active, 'completed': l10n.statusCompleted, 'rejected': l10n.statusRejected, 'cancelled': l10n.statusCancelled}[status] ?? status;
