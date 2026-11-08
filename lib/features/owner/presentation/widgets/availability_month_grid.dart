import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_availability.dart';

/// The month grid of the vehicle booking calendar: month navigation,
/// weekday header and one cell per day, coloured free / requested /
/// confirmed / past. Extracted from [OwnerVehicleCalendarView] so the
/// view stays under the 250-line cap.
class AvailabilityMonthGrid extends StatelessWidget {
  const AvailabilityMonthGrid({
    super.key,
    required this.month,
    required this.bookings,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<BookingEntity> bookings;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  /// Day-cell colour, brightness-aware: the old pale tints (grey.shade200,
  /// red/amber/green.shade50-100) glare on a dark calendar and the navy day
  /// number on them was unreadable once the cells went dark.
  Color _dayColor(BuildContext context, DateTime day) {
    final brightness = Theme.of(context).brightness;
    final today = DateTime.now();
    final d = DateTime(day.year, day.month, day.day);
    if (d.isBefore(DateTime(today.year, today.month, today.day))) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    if (isDayConfirmed(bookings, day)) {
      return AppColors.errorContainerFor(brightness);
    }
    if (isDayBlocked(bookings, day)) {
      return AppColors.warningContainerFor(brightness);
    }
    return AppColors.successContainerFor(brightness);
  }

  List<Widget> _monthCells(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first grid: DateTime.weekday is Mon=1..Sun=7.
    final leading = first.weekday - 1;
    final cells = <Widget>[];
    for (int i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = selectedDay != null &&
          selectedDay!.year == date.year &&
          selectedDay!.month == date.month &&
          selectedDay!.day == date.day;
      cells.add(
        GestureDetector(
          onTap: () => onDaySelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _dayColor(context, date),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text('$day',
                style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
        ),
      );
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () =>
                  onMonthChanged(DateTime(month.year, month.month - 1)),
            ),
            Text(_monthLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () =>
                  onMonthChanged(DateTime(month.year, month.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Mon', style: Theme.of(context).textTheme.labelSmall),
            Text('Tue', style: Theme.of(context).textTheme.labelSmall),
            Text('Wed', style: Theme.of(context).textTheme.labelSmall),
            Text('Thu', style: Theme.of(context).textTheme.labelSmall),
            Text('Fri', style: Theme.of(context).textTheme.labelSmall),
            Text('Sat', style: Theme.of(context).textTheme.labelSmall),
            Text('Sun', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _monthCells(context),
        ),
      ],
    );
  }
}
