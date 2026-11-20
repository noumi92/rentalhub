import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// O20: the approval checklist on the Booking Confirmed screen.
/// Every state is derived from the booking itself — nothing is
/// invented: the request was approved when the booking left
/// 'requested'/'rejected', the advance counts as received when the
/// paid amount covers the required advance, pickup is done once the
/// trip is active, and return is done once the booking is completed.
/// Anything not yet true renders as pending.
class BookingConfirmedChecklist extends StatelessWidget {
  const BookingConfirmedChecklist({super.key, required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final approved = {
      'approved',
      'paid',
      'active',
      'completed',
    }.contains(booking.status);
    final advanceReceived =
        booking.advancePaid >= booking.advanceRequired;
    final pickedUp = {'active', 'completed'}.contains(booking.status);
    final returned = booking.status == 'completed';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingConfirmedChecklistTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _item(
              context,
              done: approved,
              label: l10n.bookingConfirmedCheckRequestApproved,
            ),
            _item(
              context,
              done: advanceReceived,
              label: l10n.bookingConfirmedCheckAdvanceReceived,
            ),
            _item(
              context,
              done: pickedUp,
              label: l10n.bookingConfirmedCheckPickup,
            ),
            _item(
              context,
              done: returned,
              label: l10n.bookingConfirmedCheckReturn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required bool done,
    required String label,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            size: 18,
            color: done
                ? AppColors.successTextFor(brightness)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: done
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            done ? l10n.done : l10n.pending,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: done
                      ? AppColors.successTextFor(brightness)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
