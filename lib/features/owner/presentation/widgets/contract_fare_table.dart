import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/utils/money_format.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../core/theme/card_decoration.dart';

/// Finish build (O20): the fare-breakdown table on the agreement
/// summary — Daily Rate × days = Total, Advance Paid, Remaining — all
/// from the booking entity's own values. The daily rate is derived
/// (total ÷ rental days, whole rupees); the days come from the
/// pickup→return span, at least 1. Nothing here is invented: total,
/// advance and remaining are the entity's stored amounts.
class ContractFareTable extends StatelessWidget {
  final BookingEntity booking;

  const ContractFareTable({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = (booking.returnTime
                .difference(booking.pickupTime)
                .inHours /
            24)
        .ceil()
        .clamp(1, 9999);
    final dailyRate = booking.totalAmount ~/ days;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.contractFareTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _row(context, l10n.contractFareDailyRate,
              l10n.amountRs(formatRs(dailyRate))),
          _row(context, l10n.contractFareRentalDays,
              l10n.contractFareDays(days)),
          const Divider(height: 18),
          _row(context, l10n.contractFareTotal,
              l10n.amountRs(formatRs(booking.totalAmount)),
              bold: true),
          _row(context, l10n.contractFieldAdvance,
              l10n.amountRs(formatRs(booking.advancePaid))),
          _row(context, l10n.contractFieldRemaining,
              l10n.amountRs(formatRs(booking.remainingBalance))),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
                    )),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
