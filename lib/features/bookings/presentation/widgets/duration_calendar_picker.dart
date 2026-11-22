import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

class DurationCalendarPicker extends StatefulWidget {
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final int durationDays;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<int> onDurationChanged;

  /// Phase B (B3): days the car is already booked — the date picker
  /// will not let the customer pick them.
  final Set<DateTime> blockedDates;
  final bool showDurationStepper;

  const DurationCalendarPicker({
    super.key,
    required this.pickupDate,
    required this.pickupTime,
    required this.durationDays,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onDurationChanged,
    this.blockedDates = const {},
    this.showDurationStepper = true,
  });

  @override
  State<DurationCalendarPicker> createState() =>
      _DurationCalendarPickerState();
}

class _DurationCalendarPickerState extends State<DurationCalendarPicker> {
  // CU-m18: the message shown when the user picks a pickup time that
  // is already past — the pick is rejected, not applied. Cleared by
  // the next valid pick.
  String? _rejectedMessage;

  DateTime _combined(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Now + 1h as a TimeOfDay — the earliest time the time picker
  /// offers when the pickup date is today (CU-m18).
  TimeOfDay _minTimeToday() {
    final min = DateTime.now().add(const Duration(hours: 1));
    return TimeOfDay(hour: min.hour, minute: min.minute);
  }

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// The inline error for the CURRENT props — a combination that has
  /// already slipped into the past (e.g. the clock moved past it).
  String? _currentError(AppLocalizations l10n) {
    if (_combined(widget.pickupDate, widget.pickupTime)
        .isBefore(DateTime.now())) {
      return l10n.pickerPastTime;
    }
    return null;
  }

  Future<void> _pickDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final lastDate = firstDate.add(const Duration(days: 90));
    var safeInitial = DateTime(
      widget.pickupDate.year,
      widget.pickupDate.month,
      widget.pickupDate.day,
    );
    if (safeInitial.isBefore(firstDate)) safeInitial = firstDate;
    while (widget.blockedDates.contains(safeInitial) &&
        !safeInitial.isAfter(lastDate)) {
      safeInitial = safeInitial.add(const Duration(days: 1));
    }
    if (safeInitial.isAfter(lastDate)) {
      setState(() => _rejectedMessage = l10n.manualBookingCarBusy);
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (day) {
        final d = DateTime(day.year, day.month, day.day);
        return !widget.blockedDates.contains(d);
      },
    );
    if (picked == null || !mounted) return;
    // CU-m18: a past pickup time is rejected with an inline error,
    // not applied and left for the submit to catch.
    if (_combined(picked, widget.pickupTime).isBefore(DateTime.now())) {
      setState(() => _rejectedMessage = l10n.pickerPastTime);
      return;
    }
    setState(() => _rejectedMessage = null);
    widget.onDateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // CU-m18: when the date is today the time picker opens at now +
    // 1h (or the current time, whichever is later) — never at a time
    // that is already gone.
    final initialTime = _isToday(widget.pickupDate) &&
            _minutes(widget.pickupTime) < _minutes(_minTimeToday())
        ? _minTimeToday()
        : widget.pickupTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null || !mounted) return;
    if (_combined(widget.pickupDate, picked).isBefore(DateTime.now())) {
      setState(() => _rejectedMessage = l10n.pickerPastTime);
      return;
    }
    setState(() => _rejectedMessage = null);
    widget.onTimeChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // CU-m18: the rejected-pick message, or the live error when the
    // current combination has slipped into the past.
    final error = _rejectedMessage ?? _currentError(l10n);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pickerPickupSchedule,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildClickableBox(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: l10n.pickerPickupDate,
                  // CU-m4: locale date, not day/month/year digits.
                  value: DateFormat.yMMMd(
                          Localizations.localeOf(context).languageCode)
                      .format(widget.pickupDate),
                  onTap: () => _pickDate(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildClickableBox(
                  context,
                  icon: Icons.access_time_rounded,
                  label: l10n.summaryPickupTime,
                  value: widget.pickupTime.format(context),
                  onTap: () => _pickTime(context),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.dangerTextFor(
                        Theme.of(context).brightness)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.dangerTextFor(
                            Theme.of(context).brightness)),
                  ),
                ),
              ],
            ),
          ],
          if (widget.showDurationStepper) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.pickerDuration,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.pickerDecreaseDays,
                      onPressed: widget.durationDays > 1
                          ? () =>
                              widget.onDurationChanged(widget.durationDays - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(
                      l10n.pickerDays(widget.durationDays),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      tooltip: l10n.pickerIncreaseDays,
                      onPressed: widget.durationDays < 30
                          ? () =>
                              widget.onDurationChanged(widget.durationDays + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClickableBox(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
