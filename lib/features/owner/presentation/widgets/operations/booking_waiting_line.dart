import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// Item 2: the muted "Waiting for payment" line for an `approved`
/// booking — the ball is in the customer's court, so there is no
/// primary CTA. The payment deadline (set at approval time, 30
/// minutes out) renders when one was recorded, never invented.
class BookingWaitingPaymentLine extends StatelessWidget {
  const BookingWaitingPaymentLine({super.key, required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deadline = booking.paymentDeadline;
    return Row(
      children: [
        Icon(
          Icons.hourglass_top_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            deadline == null
                ? l10n.nextStepWaitingPayment
                : '${l10n.nextStepWaitingPayment} • ${l10n.paymentPayByDeadline(DateFormat('d MMM yyyy, h:mm a').format(deadline))}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
