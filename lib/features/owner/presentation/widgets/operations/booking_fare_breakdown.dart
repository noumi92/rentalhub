import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../fleet/pricing_trip_charges.dart';

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

/// Driver night stay (deck p.4, 024b): a 3-day out-of-city trip
/// shows 2 nights — nights = days − 1, so a 1-day trip has 0 nights.
int nightStayNightsFor(DateTime pickup, DateTime returnTime) =>
    math.max(0, dayCountBetween(pickup, returnTime) - 1);

/// The night-stay charge for a trip: nights × the vehicle's
/// per-night rate ([kDefaultDriverNightStayPkr] when unset).
/// Only out-of-city WITH-DRIVER trips — no driver, no night stay;
/// in-city and 1-day trips are always 0.
int nightStayTotalFor({
  required VehicleEntity? vehicle,
  required bool isWithDriver,
  required bool isOutOfCity,
  required DateTime pickup,
  required DateTime returnTime,
}) {
  if (!isOutOfCity || !isWithDriver) return 0;
  final nights = nightStayNightsFor(pickup, returnTime);
  if (nights == 0) return 0;
  return nights * (vehicle?.driverNightStayPkr ?? kDefaultDriverNightStayPkr);
}

/// Audit §5 item 2 (O15): the fare breakdown the owner booking detail
/// was missing — pickup/return dates + times, day count, the In-City /
/// Out-City tag, daily rate × days = total, advance paid and remaining.
/// The entity already carries every value; this is display work.
/// Reused by the requested detail, the approved body, the payment
/// verification view and the manual-booking confirm step.
///
/// Night stay + tolls: shown only when the vehicle (or the explicit
/// overrides) is passed — the three owner detail callers only have
/// the booking, so they show neither row. The manual confirm step
/// passes the vehicle, so it shows both.
class BookingFareBreakdown extends StatelessWidget {
  const BookingFareBreakdown({
    super.key,
    required this.booking,
    this.dailyRate,
    this.vehicle,
    this.nightStayTotal,
    this.tollsPaidBy,
  });

  final BookingEntity booking;

  /// The per-day rate to show. Defaults to the total spread over the
  /// day count, so daily rate × days always equals the total.
  final int? dailyRate;

  /// The booked vehicle. When given, the night-stay total is derived
  /// from its per-night rate and the tolls note from its tolls choice.
  final VehicleEntity? vehicle;

  /// Explicit night-stay total, overriding the vehicle derivation.
  /// Null means "derive from [vehicle]"; no vehicle means no row.
  final int? nightStayTotal;

  /// Explicit tolls choice ('customer' | 'included'), overriding the
  /// vehicle derivation. Null means "derive from [vehicle]".
  final String? tollsPaidBy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = bookingDayCount(booking);
    final isOutOfCity = booking.tripType == 'out_of_city';
    final nights = nightStayNightsFor(booking.pickupTime, booking.returnTime);
    final stay = nightStayTotal ??
        (vehicle == null
            ? 0
            : nightStayTotalFor(
                vehicle: vehicle,
                isWithDriver: booking.isWithDriver,
                isOutOfCity: isOutOfCity,
                pickup: booking.pickupTime,
                returnTime: booking.returnTime,
              ));
    // The stored total already includes the night stay (manual
    // bookings add it at creation), so the derived daily rate is the
    // total net of the stay — daily × days + night stay = total.
    final rate =
        dailyRate ?? ((booking.totalAmount - stay) / days).round();
    final tolls = tollsPaidBy ?? vehicle?.tollsPaidBy;
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
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
            // Gap (b): the stored fixed route, shown when the trip
            // was priced by fixed route — absent on older bookings
            // and on non-route trips, so no row renders then.
            if (booking.fixedRouteSummary != null &&
                booking.fixedRouteSummary!.isNotEmpty)
              _row(context, l10n.outCityFixedRouteLabel,
                  booking.fixedRouteSummary!),
            _row(context, l10n.bookingFareDailyRate,
                l10n.amountRs(formatRs(rate))),
            _row(
                context,
                l10n.bookingFareDailyRateTimes(days),
                l10n.amountRs(formatRs(rate * days))),
            if (stay > 0)
              _row(context, l10n.bookingFareNightStay(nights),
                  l10n.amountRs(formatRs(stay))),
            if (isOutOfCity && (vehicle != null || tolls != null))
              _note(
                  context,
                  tolls == 'included'
                      ? l10n.bookingFareTollsIncluded
                      : l10n.bookingFareTollsCustomer),
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

  /// A full-width note row (no amount): the tolls & parking note is
  /// "Paid by customer" / "Included in rent", never a charge.
  Widget _note(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
