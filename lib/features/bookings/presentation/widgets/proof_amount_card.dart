import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/booking_entity.dart';
import 'shop_payment_accounts.dart';

/// §11: the proof-upload summary card — vehicle, booking id, the
/// advance due (grouped rupees, C5), and the "Pay to:" line naming the
/// shop account the TID should belong to, so the payer does not have
/// to remember it from the previous screen.
class ProofAmountCard extends StatelessWidget {
  const ProofAmountCard({super.key, required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.vehicleName ?? l10n.proofSelectedCar,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      l10n.proofBookingId(booking.bookingId),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.amountRs(formatRs(booking.advanceRequired)),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.orangeTextFor(
                                Theme.of(context).brightness)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ShopPaymentAccounts(shopId: booking.shopId, singleLine: true),
        ],
      ),
    );
  }
}
