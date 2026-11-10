import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/data/sync_status_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../handover/data/datasources/pdf_contract_generator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/money_format.dart';

class BookingTicketCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final String? actionLabel;

  /// Phase B (B5): the booking's sync state, when the caller knows
  /// it (the bookings list passes it from [SyncStatusCubit]). Null
  /// means "don't show a chip" (e.g. the detail view).
  final SyncEntryStatus? syncStatus;

  const BookingTicketCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onAction,
    this.actionLabel,
    this.syncStatus,
  });

  Color _getStatusColor(String status, Brightness brightness) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return AppColors.successTextFor(brightness);
      case 'approved':
      case 'payment_submitted':
        return AppColors.secondary;
      case 'requested':
        return AppColors.warningTextFor(brightness);
      case 'cancelled':
      case 'rejected':
        return AppColors.dangerTextFor(brightness);
      default:
        return brightness == Brightness.dark ? AppColors.primaryOnDark : AppColors.primary;
    }
  }

  /// Phase B (E1): once the booking is paid, the customer shows
  /// this QR at the counter and the owner scans it to open handover.
  bool get _showQr =>
      booking.status == 'paid' || booking.status == 'active';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(booking.status, Theme.of(context).brightness);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                      l10n.ticketPickupDate(booking.pickupTime.day, booking.pickupTime.month, booking.pickupTime.year),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.bookingTotalAmount(formatRs(booking.totalAmount)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_showQr)
                Row(
                  children: [
                    QrImageView(
                      data: PdfContractGenerator.verificationUrlFor(
                          booking.bookingId),
                      size: 84,
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
              Row(
                children: [
                  // Customer Home at 200% text scale: the status chip
                  // ('PAYMENT_SUBMITTED') plus the action button are
                  // wider than the card — the chip shrinks and
                  // ellipsizes instead of overflowing.
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: statusColor),
                            ),
                          ),
                        ),
                        // Phase B (B5): per-item sync state.
                        if (syncStatus != null &&
                            syncStatus != SyncEntryStatus.synced) ...[
                          const SizedBox(width: 6),
                          SyncStatusChip(status: syncStatus!),
                        ],
                      ],
                    ),
                  ),
                  if (actionLabel != null && onAction != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.secondary,
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

