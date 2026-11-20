import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'booking_calendar_origin_colors.dart';

/// O25: the booking-calendar day view — a 9 AM–9 PM time grid, one
/// row per car, with one block per booking positioned by its pickup /
/// return time. Online blocks are navy, walk-in blocks are orange
/// ([BookingCalendarOriginColors]). Multi-day bookings are clipped to
/// the visible window; bookings that do not touch the day (or are
/// rejected / cancelled / still just a request) draw nothing.
///
/// Pure positioning lives in [dayBlockSpan] so the geometry is unit
/// testable without pumping a widget.
class CalendarDayTimeGrid extends StatelessWidget {
  /// First visible hour (9 AM) and last visible hour (9 PM), per spec.
  static const int startHour = 9;
  static const int endHour = 21;

  /// Width of the car-name label column, so the time track lines up
  /// across rows.
  static const double labelWidth = 64;

  final DateTime day;
  final List<VehicleEntity> fleet;
  final List<BookingEntity> bookings;
  final ValueChanged<VehicleEntity>? onVehicleTap;

  const CalendarDayTimeGrid({
    super.key,
    required this.day,
    required this.fleet,
    required this.bookings,
    this.onVehicleTap,
  });

  /// The booking's span as fractions of the 9 AM–9 PM window, clipped
  /// to [0, 1]; null when the booking does not intersect the window.
  /// `pickup`/`ret` are the booking's pickup and return times.
  static ({double start, double end})? dayBlockSpan({
    required DateTime pickup,
    required DateTime ret,
    required DateTime day,
  }) {
    final windowStart = DateTime(day.year, day.month, day.day, startHour);
    final windowEnd = DateTime(day.year, day.month, day.day, endHour);
    final start = pickup.isAfter(windowStart) ? pickup : windowStart;
    final end = ret.isBefore(windowEnd) ? ret : windowEnd;
    if (!start.isBefore(end)) return null;
    final span = endHour - startHour;
    final startFrac =
        (start.hour + start.minute / 60 - startHour) / span;
    final endFrac = (end.hour + end.minute / 60 - startHour) / span;
    return (
      start: startFrac.clamp(0, 1).toDouble(),
      end: endFrac.clamp(0, 1).toDouble()
    );
  }

  List<BookingEntity> _bookingsFor(String vehicleId) {
    return bookings.where((b) {
      if (b.vehicleId != vehicleId) return false;
      // Same rule as the month view: a pending request is not a
      // booking yet, and rejected / cancelled bookings are gone.
      if (b.status == 'rejected' ||
          b.status == 'cancelled' ||
          b.status == 'requested') {
        return false;
      }
      return dayBlockSpan(pickup: b.pickupTime, ret: b.returnTime, day: day) !=
          null;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final hourLabel = DateFormat('h a');
    return Column(
      children: [
        // Time header: 9 AM at the track's left edge, 9 PM at its
        // right edge, matching the spec's 9 AM / 12 PM / 3 PM / 6 PM /
        // 9 PM ruler.
        Row(
          children: [
            const SizedBox(width: labelWidth),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final h in [9, 12, 15, 18, 21])
                    Text(
                      hourLabel.format(DateTime(2026, 1, 1, h)),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...fleet.map((vehicle) {
          final blocks = _bookingsFor(vehicle.vehicleId);
          return InkWell(
            onTap: onVehicleTap == null
                ? null
                : () => onVehicleTap!(vehicle),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Text(
                      vehicle.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              for (final booking in blocks)
                                _block(
                                  context,
                                  booking,
                                  width,
                                  l10n,
                                  brightness,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _block(
    BuildContext context,
    BookingEntity booking,
    double trackWidth,
    AppLocalizations l10n,
    Brightness brightness,
  ) {
    final span = dayBlockSpan(
      pickup: booking.pickupTime,
      ret: booking.returnTime,
      day: day,
    )!;
    final origin = BookingCalendarOriginColors.originOf(booking);
    final fill = BookingCalendarOriginColors.fillFor(brightness, origin);
    final label = origin == BookingCalendarOriginColors.walkIn
        ? l10n.fleetCalendarWalkIn
        : l10n.fleetCalendarOnline;
    return Positioned(
      left: span.start * trackWidth,
      width: (span.end - span.start) * trackWidth,
      top: 4,
      bottom: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: BookingCalendarOriginColors.labelColorFor(
                    brightness, origin),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
