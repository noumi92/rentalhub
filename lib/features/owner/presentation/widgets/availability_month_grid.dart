import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
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

  String _monthLabel(AppLocalizations l10n) {
    final months = [
      l10n.calendarMonthJanuary,
      l10n.calendarMonthFebruary,
      l10n.calendarMonthMarch,
      l10n.calendarMonthApril,
      l10n.calendarMonthMay,
      l10n.calendarMonthJune,
      l10n.calendarMonthJuly,
      l10n.calendarMonthAugust,
      l10n.calendarMonthSeptember,
      l10n.calendarMonthOctober,
      l10n.calendarMonthNovember,
      l10n.calendarMonthDecember,
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
      final now = DateTime.now();
      final isToday = now.year == date.year &&
          now.month == date.month &&
          now.day == date.day;
      cells.add(
        // E3: each day is a labelled button (selected state included)
        // for screen readers; the tap behaviour is unchanged.
        Semantics(
          button: true,
          selected: isSelected,
          label: AppLocalizations.of(context)!.calendarSelectDay(day),
          child: GestureDetector(
            onTap: () => onDaySelected(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _dayColor(context, date),
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 2)
                    // Audit §7: today gets a ring (and a dot below
                    // the number) so it is distinguishable from any
                    // other free/requested/confirmed day.
                    : isToday
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2)
                        : null,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$day',
                      style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface)),
                  if (isToday)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: l10n.calendarPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () =>
                  onMonthChanged(DateTime(month.year, month.month - 1)),
            ),
            // Audit §7: the month label flexes with ellipsis — at
            // 360px / 1.35× (and the wide test font) the bare label
            // overflowed the row between the two nav buttons.
            Expanded(
              child: Text(_monthLabel(l10n),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
            ),
            IconButton(
              tooltip: l10n.calendarNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () =>
                  onMonthChanged(DateTime(month.year, month.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Audit §7: each weekday label is Expanded with centred
        // ellipsis — the bare spaceAround Row overflowed in Urdu /
        // at 1.35× text scale.
        Row(
          children: [
            for (final label in [
              l10n.calendarWeekdayMon,
              l10n.calendarWeekdayTue,
              l10n.calendarWeekdayWed,
              l10n.calendarWeekdayThu,
              l10n.calendarWeekdayFri,
              l10n.calendarWeekdaySat,
              l10n.calendarWeekdaySun,
            ])
              Expanded(
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          // E3: cells are taller than wide so a day's tap target stays
          // >= 48dp tall even on a 320px screen (7 columns of ~41dp
          // wide need childAspectRatio <= 0.85 for a 48dp height).
          childAspectRatio: 0.85,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _monthCells(context),
        ),
      ],
    );
  }
}
