import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Audit §5 item 1 (O16 p.7): the pickup + return date/time pickers
/// and the In-City / Out-City toggle the manual booking flow was
/// missing. The toggle mirrors the customer-side trip type
/// (`TripTypeSection`): out-of-city scales the package price by the
/// vehicle's out-of-city ratio and notes the tracker clearance.
class ManualBookingScheduleSection extends StatelessWidget {
  const ManualBookingScheduleSection({
    super.key,
    required this.pickupTime,
    required this.returnTime,
    required this.onPickupChanged,
    required this.onReturnChanged,
    required this.isOutOfCity,
    required this.onTripTypeChanged,
  });

  final DateTime pickupTime;
  final DateTime returnTime;
  final ValueChanged<DateTime> onPickupChanged;
  final ValueChanged<DateTime> onReturnChanged;
  final bool isOutOfCity;
  final ValueChanged<bool> onTripTypeChanged;

  static final _format = DateFormat('d MMM yyyy, h:mm a');

  Future<void> _pickDateTime(
      BuildContext context, DateTime current, ValueChanged<DateTime> onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _dateTimeButton(
                context,
                label: l10n.bookingFarePickup,
                value: _format.format(pickupTime),
                icon: Icons.calendar_month_rounded,
                onTap: () =>
                    _pickDateTime(context, pickupTime, onPickupChanged),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateTimeButton(
                context,
                label: l10n.bookingFareReturn,
                value: _format.format(returnTime),
                icon: Icons.event_available_rounded,
                onTap: () =>
                    _pickDateTime(context, returnTime, onReturnChanged),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                materialTapTargetSize: MaterialTapTargetSize.padded,
                label: Text(l10n.inCityHyphen),
                selected: !isOutOfCity,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isOutOfCity
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.white),
                onSelected: (_) => onTripTypeChanged(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                materialTapTargetSize: MaterialTapTargetSize.padded,
                label: Text(l10n.outOfCityHyphen),
                selected: isOutOfCity,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isOutOfCity
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface),
                onSelected: (_) => onTripTypeChanged(true),
              ),
            ),
          ],
        ),
        if (isOutOfCity) ...[
          const SizedBox(height: 8),
          Text(
            l10n.tripTrackerNote,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500, color: AppColors.secondary),
          ),
        ],
      ],
    );
  }

  Widget _dateTimeButton(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ,
            ),
          ],
        ),
      ),
    );
  }
}
