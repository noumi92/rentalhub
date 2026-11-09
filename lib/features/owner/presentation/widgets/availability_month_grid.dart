import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_availability.dart';

/// Day states, in priority order: past beats every booking colour,
/// then confirmed, then requested, then free.
enum CalendarDayState { past, confirmed, requested, free }

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
      l10n.calendarMonthJanuary, l10n.calendarMonthFebruary, l10n.calendarMonthMarch, l10n.calendarMonthApril,
      l10n.calendarMonthMay, l10n.calendarMonthJune, l10n.calendarMonthJuly, l10n.calendarMonthAugust,
      l10n.calendarMonthSeptember, l10n.calendarMonthOctober, l10n.calendarMonthNovember, l10n.calendarMonthDecember,
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  // Light fills are the pale containers deepened with 20% of the strong
  // status colour: before, the four fills sat 1.01-1.05:1 apart (and
  // 1.04-1.09:1 from white); after, each is 1.38-1.48:1 from the surface
  // with a visible hue, while onSurface text stays >= 12:1. Requested
  // blends orangeText (4.99:1 on its container); amber #F59E0B is only
  // 2.07:1 there and can never carry a visible edge. Dark: unchanged.
  static Color fillFor(Brightness brightness, CalendarDayState state) {
    if (brightness == Brightness.dark) {
      return switch (state) {
        CalendarDayState.past => AppColors.surfaceContainerHighestDark,
        CalendarDayState.confirmed => AppColors.errorContainerDark,
        CalendarDayState.requested => AppColors.warningContainerDark,
        CalendarDayState.free => AppColors.successContainerDark,
      };
    }
    return switch (state) {
      CalendarDayState.past => AppColors.surfaceContainerHighestLight,
      CalendarDayState.confirmed => Color.alphaBlend(AppColors.errorDark.withValues(alpha: 0.20), AppColors.errorContainer),
      CalendarDayState.requested => Color.alphaBlend(AppColors.orangeText.withValues(alpha: 0.20), AppColors.warningContainer),
      CalendarDayState.free => Color.alphaBlend(AppColors.accentSuccessStrong.withValues(alpha: 0.20), AppColors.successContainer),
    };
  }

  // Light-only state border: full-strength status colour at 1.5px (past:
  // subtle border, 1px). Border vs its fill is >= 3.2:1. Dark: no
  // per-state border — unchanged.
  static Border? borderFor(Brightness brightness, CalendarDayState state) {
    if (brightness == Brightness.dark) return null;
    return switch (state) {
      CalendarDayState.past => Border.all(color: AppColors.borderSubtle, width: 1),
      CalendarDayState.confirmed => Border.all(color: AppColors.errorDark, width: 1.5),
      CalendarDayState.requested => Border.all(color: AppColors.orangeText, width: 1.5),
      CalendarDayState.free => Border.all(color: AppColors.accentSuccessStrong, width: 1.5),
    };
  }

  // Day-number colour. Light: white on the solid selected fill (15.1:1
  // on primary), muted on past days (4.55:1), onSurface elsewhere
  // (>= 12:1 on the deepened fills). Dark: onSurface, as before. The
  // pale-container on-container tokens are NOT used: in light they read
  // 2.41:1 (success), 2.07:1 (warning), 3.44:1 (error).
  static Color numberColorFor(Brightness brightness, CalendarDayState state, {required bool isSelected}) {
    if (brightness == Brightness.dark) return AppColors.onSurfaceDark;
    if (isSelected) return Colors.white;
    if (state == CalendarDayState.past) return AppColors.onSurfaceVariantLight;
    return AppColors.onSurfaceLight;
  }

  CalendarDayState _dayState(DateTime day) {
    final today = DateTime.now();
    if (DateTime(day.year, day.month, day.day).isBefore(DateTime(today.year, today.month, today.day))) return CalendarDayState.past;
    if (isDayConfirmed(bookings, day)) return CalendarDayState.confirmed;
    if (isDayBlocked(bookings, day)) return CalendarDayState.requested;
    return CalendarDayState.free;
  }

  /// Cell border. Light: the solid primary fill IS the selected marker
  /// (no border), so it cannot be confused with today's 2px primary ring
  /// — before, selected (onSurface) vs today (primary) measured 1.18:1.
  /// Dark: the old rings stay.
  Border? _cellBorder(BuildContext context, CalendarDayState state, bool isSelected, bool isToday) {
    final scheme = Theme.of(context).colorScheme;
    if (isSelected) return Theme.of(context).brightness == Brightness.light ? null : Border.all(color: scheme.onSurface, width: 2);
    if (isToday) return Border.all(color: scheme.primary, width: 2);
    return borderFor(Theme.of(context).brightness, state);
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
      final brightness = Theme.of(context).brightness;
      final state = _dayState(date);
      cells.add(
        // E3: each day is a labelled button for screen readers.
        Semantics(
          button: true,
          selected: isSelected,
          label: AppLocalizations.of(context)!.calendarSelectDay(day),
          child: GestureDetector(
            onTap: () => onDaySelected(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected && brightness == Brightness.light
                    ? Theme.of(context).colorScheme.primary
                    : fillFor(brightness, state),
                borderRadius: BorderRadius.circular(8),
                border: _cellBorder(context, state, isSelected, isToday),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$day',
                      style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: numberColorFor(brightness, state,
                              isSelected: isSelected))),
                  if (isToday)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: isSelected && brightness == Brightness.light
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
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
            // Audit §7: month label flexes with ellipsis (overflowed
            // at 360px / 1.35x between the two nav buttons).
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
        // Audit §7: weekday labels are Expanded with centred ellipsis
        // (the bare spaceAround Row overflowed in Urdu / at 1.35x).
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
          // >= 48dp tall even on a 320px screen (childAspectRatio <= 0.85).
          childAspectRatio: 0.85,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _monthCells(context),
        ),
      ],
    );
  }
}
