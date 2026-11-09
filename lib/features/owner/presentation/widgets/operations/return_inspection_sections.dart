import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// Audit item 5/18 (O25): the return landing — booking summary with
/// the return-due line and the "Start Return Inspection" entry.
/// Finish build: the landing is now its own route
/// (`/owner/return-landing/:id`, [OwnerReturnLandingView]) and this
/// section is its content; the return view itself starts directly at
/// the inspection. Start navigates to `/owner/return/:id`.
class ReturnLandingSection extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback onStart;

  const ReturnLandingSection({
    super.key,
    required this.booking,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.returnLandingSummary(
                  booking.bookingId,
                  booking.customerName ?? l10n.requestsCustomerFallback,
                  booking.vehicleName ?? l10n.summaryVehicle,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _row(context, l10n.returnLandingDueBack,
            _dateTime(context, booking.returnTime)),
        _row(context, l10n.returnFareRent,
            l10n.amountRs(formatRs(booking.totalAmount))),
        _row(context, l10n.returnFareRemaining,
            l10n.amountRs(formatRs(booking.remainingBalance))),
        const SizedBox(height: 20),
        DebouncedButton(
          text: l10n.returnLandingStart,
          icon: Icons.fact_check_rounded,
          onPressed: onStart,
        ),
      ],
    );
  }

  String _dateTime(BuildContext context, DateTime d) {
    final date = MaterialLocalizations.of(context).formatShortDate(d);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(d),
    );
    return '$date · $time';
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
        ],
      ),
    );
  }
}

/// The return-inspection condition: Good, or Minor damage (which
/// points the owner at the Record Damage screen).
class ReturnConditionSelector extends StatelessWidget {
  final String bookingId;
  final String condition; // 'good' | 'minor_damage'
  final ValueChanged<String> onChanged;

  const ReturnConditionSelector({
    super.key,
    required this.bookingId,
    required this.condition,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.returnConditionTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(l10n.returnConditionGood),
                  selected: condition == 'good',
                  onSelected: (v) {
                    if (v) onChanged('good');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(l10n.returnConditionMinorDamage),
                  selected: condition == 'minor_damage',
                  onSelected: (v) {
                    if (v) onChanged('minor_damage');
                  },
                ),
              ),
            ],
          ),
          if (condition == 'minor_damage') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.car_crash_rounded, size: 18),
                label: Text(l10n.returnConditionRecordDamage),
                onPressed: () => context.push(
                  RouteNames.ownerRecordDamage
                      .replaceFirst(':id', bookingId),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
