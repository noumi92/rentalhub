import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/data/sync_status_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/presentation/widgets/booking_status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money_format.dart';

class BookingTicketCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final String? actionLabel;

  /// Phase B (B5): the booking's sync state, when the caller knows
  /// it (the bookings list passes it from [SyncStatusCubit]). Null
  /// means "don't show a chip" (e.g. the detail view).
  final SyncEntryStatus? syncStatus;

  const BookingTicketCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onAction,
    this.actionLabel,
    this.syncStatus,
  });

  /// Phase B (E1): once the booking is paid, the customer shows
  /// this QR at the counter and the owner scans it to open handover.
  bool get _showQr =>
      booking.status == 'paid' || booking.status == 'active';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      // Customer pass (2026-11-16): the theme Card is the canonical
      // showroom card — no per-file shape override.
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.vehicleName ?? l10n.rentalCar,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          booking.shopName ?? l10n.showroomLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (booking.vehiclePlate != null &&
                      booking.vehiclePlate!.isNotEmpty)
                    PakistaniPlateWidget(
                      plateNumber: booking.vehiclePlate!,
                      isCompact: true,
                    ),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      // Audit 2026-11-15 DS-5: the key now takes one
                      // localized date string, never day/month/year parts.
                      l10n.ticketPickupDate(formatDate(context, booking.pickupTime)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.bookingTotalAmount(formatRs(booking.totalAmount)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_showQr)
                Row(
                  children: [
                    QrImageView(
                      data: booking.bookingId,
                      size: 84,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      semanticsLabel: l10n.ticketShowCode,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.ticketShowCode,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              if (_showQr) const SizedBox(height: 10),
              // CU-M5: the status is a human label from
              // [BookingStatusChip], never the raw enum — and the row
              // wraps instead of ellipsizing the status at 200%
              // text scale, so the action the user must take stays
              // readable. The action button is a full 48dp target.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  BookingStatusChip(status: booking.status),
                  // Phase B (B5): per-item sync state.
                  if (syncStatus != null &&
                      syncStatus != SyncEntryStatus.synced)
                    SyncStatusChip(status: syncStatus!),
                  if (actionLabel != null && onAction != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(actionLabel!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

