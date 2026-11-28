import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/presentation/widgets/booking_status_chip.dart';
import '../../../../bookings/presentation/widgets/digital_qr_pass_widget.dart';
import '../../../../../l10n/app_localizations.dart';

/// Home redesign (2026-11-24): the dense Home booking card — one
/// card per recent booking, no tall QR block, no divider. Top row:
/// car + shop on the left, plate badge on the right. Middle row:
/// pickup date on the left, bold total on the right. Bottom row:
/// status pill + the inline action link. Paid/active bookings get a
/// compact 56x56 QR thumbnail at the right (plate above it) that
/// opens the bright QR pass modal — the counter handover QR without
/// the vertical cost of the ticket card's 84px block.
///
/// The QR tile is white with dark modules in BOTH themes: a
/// scannable QR needs a light quiet zone (same rule as
/// [DigitalQrPassWidget], whose whole pass is forced light).
class HomeBookingCard extends StatelessWidget {
  const HomeBookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.actionLabel,
    this.onAction,
  });

  final BookingEntity booking;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Paid or on the road — the booking's counter handover QR.
  bool get _showQr =>
      booking.status == 'paid' || booking.status == 'active';

  bool get _hasRightColumn =>
      (booking.vehiclePlate?.isNotEmpty ?? false) || _showQr;

  void _showPass(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          // The pass widget paints its own forced-light surface
          // (BoxDecoration color, radius 20) — the dialog itself
          // keeps the theme background, the same as the full-screen
          // pass view. Never set backgroundColor here: the A4
          // dark-mode test forbids a forced light dialog background.
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: DigitalQrPassWidget(
              bookingId: booking.bookingId,
              vehicleName: booking.vehicleName ?? l10n.rentalCar,
              // CU-M12: a missing plate renders '—', never a fake.
              plateNumber: booking.vehiclePlate ?? '—',
              shopName: booking.shopName ?? l10n.showroomLabel,
              pickupTime: booking.pickupTime,
              bookingStatus: booking.status,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: AppCardDecoration.of(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(AppDimensions.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicleName ?? l10n.rentalCar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        booking.shopName ?? l10n.showroomLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              // Audit 2026-11-15 DS-5: the key now
                              // takes one localized date string, never
                              // day/month/year parts.
                              l10n.ticketPickupDate(formatDate(
                                  context, booking.pickupTime)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.bookingTotalAmount(
                                  formatRs(booking.totalAmount)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // CU-M5: the status/action row wraps instead of
                      // ellipsizing the status at 200% text scale, so
                      // the action the user must take stays readable.
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          BookingStatusChip(status: booking.status),
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
                if (_hasRightColumn) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (booking.vehiclePlate != null &&
                          booking.vehiclePlate!.isNotEmpty)
                        PakistaniPlateWidget(
                          plateNumber: booking.vehiclePlate!,
                          isCompact: true,
                        ),
                      if (_showQr) ...[
                        const SizedBox(height: 8),
                        Tooltip(
                          message: l10n.bookingsViewPass,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showPass(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 56,
                                height: 56,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Theme.of(context).dividerColor),
                                ),
                                child: QrImageView(
                                  data: booking.bookingId,
                                  size: 48,
                                  semanticsLabel: l10n.ticketShowCode,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
