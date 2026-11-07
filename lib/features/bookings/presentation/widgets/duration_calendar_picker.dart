import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DurationCalendarPicker extends StatelessWidget {
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final int durationDays;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<int> onDurationChanged;

  /// Phase B (B3): days the car is already booked — the date picker
  /// will not let the customer pick them.
  final Set<DateTime> blockedDates;

  const DurationCalendarPicker({
    super.key,
    required this.pickupDate,
    required this.pickupTime,
    required this.durationDays,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onDurationChanged,
    this.blockedDates = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Schedule',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildClickableBox(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: 'Pickup Date',
                  value:
                      '${pickupDate.day}/${pickupDate.month}/${pickupDate.year}',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: pickupDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      selectableDayPredicate: (day) {
                        final d = DateTime(day.year, day.month, day.day);
                        return !blockedDates.contains(d);
                      },
                    );
                    if (picked != null) onDateChanged(picked);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildClickableBox(
                  context,
                  icon: Icons.access_time_rounded,
                  label: 'Pickup Time',
                  value: pickupTime.format(context),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: pickupTime,
                    );
                    if (picked != null) onTimeChanged(picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rental Duration',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: durationDays > 1
                        ? () => onDurationChanged(durationDays - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppColors.primary,
                  ),
                  Text(
                    '$durationDays Day${durationDays > 1 ? "s" : ""}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  IconButton(
                    onPressed: durationDays < 30
                        ? () => onDurationChanged(durationDays + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
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
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
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

