import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';

/// The out-of-city extras on the manual-booking confirm step: the
/// night-stay component of the booked total, plus the tolls note.
/// Extracted from `OwnerManualBookingConfirmView` so the view stays
/// under the 250-line cap (rulebook §2.2). The night-stay row renders
/// only when the trip actually stays over.
class ManualBookingOutCityExtras extends StatelessWidget {
  const ManualBookingOutCityExtras({
    super.key,
    required this.nights,
    required this.nightStay,
    required this.tollsIncluded,
  });

  final int nights;
  final int nightStay;
  final bool tollsIncluded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nightStay > 0)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(l10n.bookingFareNightStay(nights))), Text(l10n.amountRs(formatRs(nightStay)), style: const TextStyle(fontWeight: FontWeight.w800))]),
            Text(tollsIncluded ? l10n.bookingFareTollsIncluded : l10n.bookingFareTollsCustomer, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
