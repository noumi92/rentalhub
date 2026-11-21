import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/utils/booking_request_time.dart';
import 'booking_fare_breakdown.dart';

/// The booking summary section of [RequestTriageCard] — vehicle +
/// fare, package / drive mode, pickup-return dates + day count, and
/// the "Waiting …" line. Extracted so the card stays under the
/// 250-line cap; the text, props and callbacks are unchanged.
class RequestTriageSummary extends StatelessWidget {
  final BookingEntity booking;

  /// FG-4: the request time behind the wait line. Null renders no
  /// line, never an invented one.
  final DateTime? requestedAt;

  const RequestTriageSummary({
    super.key,
    required this.booking,
    this.requestedAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    // Local copy so the null check below promotes the type for
    // DateTime.now().difference(...) (a field does not promote).
    final requestedAt = this.requestedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                booking.vehicleName ?? l10n.requestsRequestedCar,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ,
              ),
            ),
            const SizedBox(width: 8),
            // E3: the amount shrinks to fit instead of overflowing —
            // at 200% text scale 'Rs. 1250000' is wider than the card
            // and pushed the row 23px past the edge. A money amount
            // must stay fully visible, so it scales down rather than
            // ellipsizing.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  // C5: grouped rupees, via the localised wrapper.
                  l10n.amountRs(formatRs(booking.totalAmount)),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      // OW-m34: the amount is orange text, not the
                      // secondary teal — same token as the status
                      // label above it.
                      color: AppColors.orangeTextFor(
                          Theme.of(context).brightness)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          // The package code (e.g. '24h') is stored data and stays
          // as-is; only the drive-mode words are localized.
          '${booking.packageType.toUpperCase()} • ${booking.isWithDriver ? l10n.requestsWithChauffeur : l10n.selfDrive}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        // Audit §5 item 2 (O14): the pickup/return dates and the
        // day count the request cards were missing.
        Text(
          // Audit 2026-11-15 DS-5: localized day + time, never a bare DateFormat.
          '${formatDayTime(context, booking.pickupTime)} → ${formatDayTime(context, booking.returnTime)} • ${l10n.bookingDaysCount(bookingDayCount(booking))}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        // FG-4: how long the request has waited — the card's job
        // is "decide oldest first". No known request time renders
        // no line, never an invented one.
        if (requestedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.requestsWaitingTime(waitDurationLabel(
                l10n, DateTime.now().difference(requestedAt))),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: booking.status == 'payment_submitted'
                      ? AppColors.warningTextFor(brightness)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
