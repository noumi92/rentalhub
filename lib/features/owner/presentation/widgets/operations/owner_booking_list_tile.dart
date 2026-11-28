import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// Compact, scannable booking list row. Shows essential info only
/// (#ID, status badge, customer, vehicle, date, total & remaining dues)
/// — all full details and action buttons live on the Booking Details page.
class OwnerBookingListTile extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback onTap;

  const OwnerBookingListTile({
    super.key,
    required this.booking,
    required this.onTap,
  });

  String _statusLabel(AppLocalizations l10n, String status) => {
        'requested': l10n.requestsStatusRequested,
        'payment_submitted': l10n.statusProofSubmitted,
        'approved': l10n.statusApproved,
        'paid': l10n.statusPaid,
        'active': l10n.active,
        'completed': l10n.statusCompleted,
        'rejected': l10n.statusRejected,
        'cancelled': l10n.statusCancelled,
        'disputed': l10n.statusDisputed,
      }[status] ??
      status;

  (Color bg, Color fg) _badgeColors(BuildContext context, String status) {
    final brightness = Theme.of(context).brightness;
    return switch (status) {
      'payment_submitted' || 'disputed' || 'approved' => (
          AppColors.orangeContainerFor(brightness),
          AppColors.orangeTextFor(brightness),
        ),
      'paid' || 'active' || 'completed' => (
          AppColors.successContainerFor(brightness),
          AppColors.successTextFor(brightness),
        ),
      'rejected' || 'cancelled' => (
          Theme.of(context).colorScheme.errorContainer,
          Theme.of(context).colorScheme.onErrorContainer,
        ),
      _ => (
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = booking;
    final (chipBg, chipFg) = _badgeColors(context, b.status);
    final hasDues = b.remainingBalance > 0 &&
        b.status != 'cancelled' &&
        b.status != 'rejected';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('booking_tile_${b.bookingId}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#${b.bookingId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(l10n, b.status),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: chipFg,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.customerName ?? l10n.requestsCustomerFallback,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${b.vehicleName ?? l10n.summaryVehicle} • ${formatDate(context, b.pickupTime)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.amountRs(formatRs(b.totalAmount)),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (hasDues)
                          Text(
                            '${l10n.bookingFareRemaining}: ${l10n.amountRs(formatRs(b.remainingBalance))}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.orangeTextFor(
                                      Theme.of(context).brightness),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
