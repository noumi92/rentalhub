import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/models/booking_model.dart';
import 'admin_list_card.dart';
import 'admin_status_chip.dart';

/// Phase 3 (3.4) — one row of the bookings list, extracted from
/// [AdminBookingsView] so the view stays under the 250-line cap with
/// its pagination and server search. Tap opens the booking detail.
///
/// Phase 4 (4.1) — the row is the shared [AdminListCard] shell and
/// the chip is [AdminStatusChip.bookingStatus] (the bookings tone
/// mapping lives there now, not in a private helper here).
class AdminBookingListTile extends StatelessWidget {
  const AdminBookingListTile({
    super.key,
    required this.booking,
    required this.compact,
    required this.onTap,
  });

  final BookingModel booking;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = booking;
    final subtitleText =
        '${b.customerName ?? l10n.admin2_bookingsCustomer} • ${b.shopName ?? ''} • ${l10n.amountRs(formatRs(b.totalAmount))} • ${humanizeStatus(b.tripType, l10n)}';
    final subtitleStyle = TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant);
    return AdminListCard(
      icon: Icons.receipt_long_rounded,
      title: '${b.vehicleName ?? b.vehicleId} • ${b.bookingId}',
      subtitleWidget: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(subtitleText, style: subtitleStyle),
                const SizedBox(height: 6),
                AdminStatusChip.bookingStatus(
                    b.status, AppLocalizations.of(context)),
              ],
            )
          : null,
      subtitle: compact ? null : subtitleText,
      isThreeLine: compact,
      trailing: compact
          ? null
          : AdminStatusChip.bookingStatus(
              b.status, AppLocalizations.of(context)),
      onTap: onTap,
    );
  }
}
