import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/utils/booking_next_step.dart';
import 'booking_waiting_line.dart';

/// Item 2: the Confirmed screen's resolver-driven primary action
/// plus the "View Booking" button, extracted so the view stays
/// under the 250-line cap. The primary follows the shared
/// resolver — paid → Start Handover, active → Return &
/// Settlement, approved → no primary, the waiting line instead.
/// "View Booking" is hidden for `paid` / `active`: the detail
/// route sends those back to the Confirmed screen, so it IS the
/// detail then and the button would loop. It stays for the other
/// statuses (e.g. `approved`, where the detail route shows the
/// accounts view).
class BookingConfirmedActions extends StatelessWidget {
  const BookingConfirmedActions({super.key, required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = resolveOwnerNextStep(booking);
    final destination = step.destination(booking);
    final showViewBooking =
        booking.status != 'paid' && booking.status != 'active';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (destination != null)
          DebouncedButton(
            text: step.label(l10n, booking),
            icon: step.kind == BookingNextStepKind.returnSettlement
                ? Icons.keyboard_return_rounded
                : Icons.key_rounded,
            onPressed: () => context.push(destination),
          )
        else if (booking.status == 'approved')
          BookingWaitingPaymentLine(booking: booking)
        else
          const SizedBox.shrink(),
        if (showViewBooking) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                RouteNames.ownerRequestsDetail
                    .replaceFirst(':id', booking.bookingId),
              ),
              icon: const Icon(Icons.receipt_long_rounded),
              label: Text(l10n.bookingConfirmedViewBooking),
            ),
          ),
        ],
      ],
    );
  }
}
