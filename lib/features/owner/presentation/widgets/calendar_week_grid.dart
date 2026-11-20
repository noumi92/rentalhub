import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'booking_calendar_origin_colors.dart';
import 'calendar_day_time_grid.dart';

/// O25: the booking-calendar week view — one column per day (Monday
/// first), one row per car. A cell carries one mini-block per origin
/// present that day (navy = online, orange = walk-in), so a day with
/// both kinds shows both. Tapping a day jumps to the Day view for
/// that date; tapping a car name opens the per-vehicle calendar.
///
/// Pure origin lookup lives in [weekDayOrigins] so the day → origins
/// mapping is unit testable without pumping a widget.
class CalendarWeekGrid extends StatelessWidget {
  static const double labelWidth = CalendarDayTimeGrid.labelWidth;

  final DateTime weekStart;
  final List<VehicleEntity> fleet;
  final List<BookingEntity> bookings;
  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<VehicleEntity>? onVehicleTap;

  const CalendarWeekGrid({
    super.key,
    required this.weekStart,
    required this.fleet,
    required this.bookings,
    this.onDaySelected,
    this.onVehicleTap,
  });

  /// The origins booked for [vehicleId] on [day] (same status rule
  /// as the month view: requests / rejected / cancelled excluded).
  static Set<String> weekDayOrigins(
    List<BookingEntity> bookings,
    String vehicleId,
    DateTime day,
  ) {
    final d = DateTime(day.year, day.month, day.day);
    final origins = <String>{};
    for (final b in bookings) {
      if (b.vehicleId != vehicleId) continue;
      if (b.status == 'rejected' ||
          b.status == 'cancelled' ||
          b.status == 'requested') {
        continue;
      }
      final from =
          DateTime(b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
      final to =
          DateTime(b.returnTime.year, b.returnTime.month, b.returnTime.day);
      if (!d.isBefore(from) && !d.isAfter(to)) {
        origins.add(BookingCalendarOriginColors.originOf(b));
      }
    }
    return origins;
  }

  List<DateTime> get _days =>
      List.generate(7, (i) => weekStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dayLabel = DateFormat('EEE');
    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;
    return Column(
      children: [
        // Day headers — tappable: jump to the Day view for that date.
        Row(
          children: [
            const SizedBox(width: labelWidth),
            for (final day in _days)
              Expanded(
                child: InkWell(
                  onTap: onDaySelected == null
                      ? null
                      : () => onDaySelected!(day),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Text(
                          dayLabel.format(day),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '${day.day}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: isToday(day)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday(day)
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ...fleet.map((vehicle) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: InkWell(
                    onTap: onVehicleTap == null
                        ? null
                        : () => onVehicleTap!(vehicle),
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
                ),
                for (final day in _days)
                  Expanded(
                    child: InkWell(
                      onTap: onDaySelected == null
                          ? null
                          : () => onDaySelected!(day),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: isToday(day)
                              ? Border.all(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Column(
                          children: [
                            for (final origin in weekDayOrigins(
                                bookings, vehicle.vehicleId, day))
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: BookingCalendarOriginColors.fillFor(
                                        brightness, origin),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
