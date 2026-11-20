import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// O25 extraction: the fleet calendar's Month view, unchanged from
/// [OwnerFleetCalendarView] — one card per car with one segment per
/// day of the month (Booked = red, Available = green), a ring on
/// today, tap a car to open its per-vehicle calendar. Extracted so
/// the view can host the Month / Day / Week toggle without passing
/// the 250-line cap. BP-16 margins are preserved: inter-card 12 dp,
/// last card 0 (the list padding is the bottom gap).
class CalendarMonthFleetGrid extends StatelessWidget {
  final DateTime month;
  final List<VehicleEntity> fleet;
  final List<BookingEntity> bookings;
  final ValueChanged<VehicleEntity>? onVehicleTap;

  const CalendarMonthFleetGrid({
    super.key,
    required this.month,
    required this.fleet,
    required this.bookings,
    this.onVehicleTap,
  });

  bool _isBooked(String vehicleId, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return bookings.any((b) {
      if (b.vehicleId != vehicleId) return false;
      // OW-m33: 'requested' is a pending ask, not a booking —
      // it used to paint the car red before anyone approved it.
      if (b.status == 'rejected' ||
          b.status == 'cancelled' ||
          b.status == 'requested') {
        return false;
      }
      final from =
          DateTime(b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
      final to =
          DateTime(b.returnTime.year, b.returnTime.month, b.returnTime.day);
      return !d.isBefore(from) && !d.isAfter(to);
    });
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return month.year == now.year &&
        month.month == now.month &&
        day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return Column(
      children: [
        ...fleet.asMap().entries.map((entry) => Card(
              // BP-16: the last card carries no bottom margin — the
              // list padding (16 dp) is the bottom gap.
              margin: EdgeInsets.only(
                  bottom: entry.key == fleet.length - 1 ? 0 : 12),
              child: InkWell(
                onTap: onVehicleTap == null
                    ? null
                    : () => onVehicleTap!(entry.value),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            entry.value.plateNumber,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // One segment per day of the month: booked =
                      // red, else green.
                      Row(
                        children: [
                          for (int day = 1; day <= daysInMonth; day++)
                            Expanded(
                              child: Container(
                                height: 18,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 0.5),
                                decoration: BoxDecoration(
                                  color: _isBooked(
                                          entry.value.vehicleId,
                                          DateTime(month.year, month.month,
                                              day))
                                      ? AppColors.errorContainerFor(
                                          Theme.of(context).brightness)
                                      : AppColors.successContainerFor(
                                          Theme.of(context).brightness),
                                  borderRadius: BorderRadius.circular(2),
                                  // OW-m33: a ring on today so the
                                  // owner can find the current day at
                                  // a glance.
                                  border: _isToday(day)
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 1.5,
                                        )
                                      : null,
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
    );
  }
}
