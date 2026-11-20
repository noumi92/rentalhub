import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'booking_calendar_origin_colors.dart';

/// O25: the fleet-calendar legend + overlap note, extracted from
/// [OwnerFleetCalendarView] so the view stays under the 250-line cap.
///
/// Month mode keeps the original Booked (red) / Available (green)
/// legend; Day and Week modes show the origin legend — Online
/// booking (navy) / Manual booking (orange) — matching the blocks in
/// the day time-grid and the week grid. The overlap note is spec copy
/// (Step 4B, O25); it describes the creation-time vehicle-status
/// lock, not a time-window overlap check (not built — see O25 report).
class FleetCalendarLegend extends StatelessWidget {
  final bool isMonthMode;

  const FleetCalendarLegend({super.key, required this.isMonthMode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 16,
      runSpacing: 8,
      children: isMonthMode
          ? [
              _swatch(
                context,
                AppColors.errorContainerFor(brightness),
                AppColors.errorOnContainerFor(brightness),
                l10n.fleetCalendarBooked,
              ),
              _swatch(
                context,
                AppColors.successContainerFor(brightness),
                AppColors.successBorderFor(brightness),
                l10n.fleetCalendarAvailable,
              ),
            ]
          : [
              _originSwatch(
                context,
                BookingCalendarOriginColors.online,
                l10n.fleetCalendarOnlineBooking,
              ),
              _originSwatch(
                context,
                BookingCalendarOriginColors.walkIn,
                l10n.fleetCalendarManualBooking,
              ),
            ],
    );
  }

  Widget _swatch(
      BuildContext context, Color color, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            // OW-m33: the pale swatches were indistinguishable at a
            // glance — a matching border + a bold label tell them apart.
            border: Border.all(color: border, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _originSwatch(BuildContext context, String origin, String label) {
    final fill = BookingCalendarOriginColors.fillFor(
        Theme.of(context).brightness, origin);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// The spec's overlap note, shown under the legend in every mode.
class FleetCalendarOverlapNote extends StatelessWidget {
  const FleetCalendarOverlapNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.fleetCalendarOverlapNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
