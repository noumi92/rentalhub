import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// O20 (extracted from [OwnerBookingConfirmedView] so the view stays
/// under the 250-line cap): the green confirmed header — check, title,
/// booking id, handover time — plus the "Reserved" car chip: the
/// vehicle is held for this booking until pickup, so the header says
/// so instead of leaving the owner to guess whether the car can be
/// booked out again.
class BookingConfirmedHeader extends StatelessWidget {
  const BookingConfirmedHeader({
    super.key,
    required this.bookingId,
    required this.handoverLine,
  });

  final String bookingId;
  final String handoverLine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSuccess.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.accentSuccess.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 48,
              color: AppColors.successTextFor(
                  Theme.of(context).brightness)),
          const SizedBox(height: 8),
          Text(
            l10n.bookingConfirmedTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.paymentVerificationBooking(bookingId),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            handoverLine,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successContainerFor(
                  Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 14,
                  color: AppColors.successTextFor(
                      Theme.of(context).brightness),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.bookingConfirmedReserved,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.successTextFor(
                            Theme.of(context).brightness),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
