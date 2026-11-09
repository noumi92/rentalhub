import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// Whole days between two moments, rounded up, at least 1 — the day
/// count the deck shows on request cards and in fare breakdowns
/// ("26–29 Oct, 3 days"). A sub-day rental still counts as 1 day.
int dayCountBetween(DateTime start, DateTime end) {
  final minutes = end.difference(start).inMinutes;
  if (minutes <= 0) return 1;
  return (minutes / (24 * 60)).ceil();
}

/// [dayCountBetween] for a booking's pickup/return pair.
int bookingDayCount(BookingEntity booking) =>
    dayCountBetween(booking.pickupTime, booking.returnTime);

/// Audit §5 item 2 (O15): the fare breakdown the owner booking detail
/// was missing — pickup/return dates + times, day count, the In-City /
/// Out-City tag, daily rate × days = total, advance paid and remaining.
/// The entity already carries every value; this is display work.
/// Reused by the requested detail, the approved body, the payment
/// verification view and the manual-booking confirm step.
class BookingFareBreakdown extends StatelessWidget {
  const BookingFareBreakdown({
    super.key,
    required this.booking,
    this.dailyRate,
  });

  final BookingEntity booking;

  /// The per-day rate to show. Defaults to the total spread over the
  /// day count, so daily rate × days always equals the total.
  final int? dailyRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = bookingDayCount(booking);
    final rate = dailyRate ?? (booking.totalAmount / days).round();
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final isOutOfCity = booking.tripType == 'out_of_city';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.bookingFareTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOutOfCity
                        ? l10n.outOfCityHyphen
                        : l10n.inCityHyphen,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _row(context, l10n.bookingFarePickup,
                dateFormat.format(booking.pickupTime)),
            _row(context, l10n.bookingFareReturn,
                dateFormat.format(booking.returnTime)),
            _row(context, l10n.bookingFareDailyRate,
                l10n.amountRs(formatRs(rate))),
            _row(
                context,
                l10n.bookingFareDailyRateTimes(days),
                l10n.amountRs(formatRs(rate * days))),
            const Divider(height: 20),
            _row(context, l10n.bookingFareTotal,
                l10n.amountRs(formatRs(booking.totalAmount)),
                bold: true),
            _row(context, l10n.bookingFareAdvanceRequired,
                l10n.amountRs(formatRs(booking.advanceRequired))),
            _row(context, l10n.bookingFareAdvancePaid,
                l10n.amountRs(formatRs(booking.advancePaid))),
            _row(context, l10n.bookingFareRemaining,
                l10n.amountRs(formatRs(booking.remainingBalance)),
                bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Both sides flex + ellipsis: at 360px / 1.35x the long
          // "Daily rate × N days" label alone exceeds the row width.
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
