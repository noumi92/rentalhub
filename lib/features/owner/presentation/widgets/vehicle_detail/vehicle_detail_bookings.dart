import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/presentation/widgets/booking_status_chip.dart';

/// Showroom redesign (Phase 2, 2026-11-16): the vehicle-detail
/// bookings section, extracted from [OwnerVehicleDetailView] so the
/// view stays under the 250-line cap. Unchanged — the section stays
/// below the rates card: title, loading / honest empty state, or one
/// card per booking with the status-coloured chip. The booking-chip
/// fill helper moves here with it.
class VehicleDetailBookings extends StatelessWidget {
  final List<BookingEntity> bookings;
  final bool loading;

  const VehicleDetailBookings({
    super.key,
    required this.bookings,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.vehicleDetailBookingsTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (loading)
          AppLoadingState(message: l10n.vehicleDetailBookingsTitle)
        else if (bookings.isEmpty)
          Text(l10n.vehicleDetailNoBookings, style: Theme.of(context).textTheme.bodyMedium)
        else
          ...bookings.map((b) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(b.customerName ?? b.customerId, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${b.packageType} • ${DateFormat('d MMM, h:mm a', Localizations.localeOf(context).languageCode).format(b.pickupTime)} → ${DateFormat('d MMM, h:mm a', Localizations.localeOf(context).languageCode).format(b.returnTime)}'), // Audit 2026-11-15 DS-5: locale passed explicitly (was a bare DateFormat).
                  // OW-m15: the booking chip is coloured by status (was raw
                  // text on the default chip). FG-10: the label is localised
                  // too — the raw stored code never shows.
                  trailing: Chip(label: Text(BookingStatusChip.labelFor(l10n, b.status), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)), backgroundColor: _bookingStatusColor(b.status)),
                ),
              )),
      ],
    );
  }
}

/// Booking-chip fill by status (OW-m15): settled/approved/active
/// green, rejected/cancelled red, everything else (requested, proof
/// submitted) orange. White label text — all three fills are >= 4.5:1.
Color _bookingStatusColor(String status) => switch (status) { 'completed' || 'paid' || 'approved' || 'active' => AppColors.accentSuccessStrong, 'rejected' || 'cancelled' => AppColors.errorDark, _ => AppColors.orangeFill };
