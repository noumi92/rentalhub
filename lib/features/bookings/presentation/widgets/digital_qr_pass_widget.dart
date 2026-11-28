import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../l10n/app_localizations.dart';

class DigitalQrPassWidget extends StatelessWidget {
  final String bookingId;
  final String vehicleName;
  final String plateNumber;
  final String shopName;
  final DateTime pickupTime;
  // Audit 2026-11-15 PW-10: the booking status the pass is for.
  // Only a paid/active booking shows a QR — any other status
  // renders the not-valid state instead. Null keeps the old
  // behaviour (QR shown) for callers that do not pass a status yet.
  final String? bookingStatus;

  const DigitalQrPassWidget({
    super.key,
    required this.bookingId,
    required this.vehicleName,
    required this.plateNumber,
    required this.shopName,
    required this.pickupTime,
    this.bookingStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    // Audit 2026-11-15 FG-13 / PW-10: the WHOLE pass is forced
    // light in both themes (the QR needs a light quiet zone, and
    // the caption was unreadable dark-on-light text on a light
    // panel in dark mode). Every text colour below is therefore a
    // dark-on-light token, never the theme's onSurface.
    const lightOnSurface = AppColors.onSurfaceLight;
    const lightOnSurfaceVariant = AppColors.onSurfaceVariantLight;
    final isValid = bookingStatus == null ||
        bookingStatus == 'paid' ||
        bookingStatus == 'active';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: lightOnSurface),
                    ),
                    Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: lightOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PakistaniPlateWidget(plateNumber: plateNumber, isCompact: true),
            ],
          ),
          const SizedBox(height: 16),
          // Digital QR container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: isValid
                ? Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    // The QR tile itself stays white in both modes:
                    // a scannable QR needs a light quiet zone.
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // CU-C2: a real scannable QR (the agreement
                        // verification URL, same as the ticket card),
                        // not a decorative icon. The owner scans this
                        // at handover; the bookingId below stays as
                        // the manual fallback.
                        QrImageView(
                          data: bookingId,
                          size: 110,
                        ),
                        Text(
                          bookingId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 1.1, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.passShowQr,
                  textAlign: TextAlign.center,
                  // Audit 2026-11-15 FG-13: the caption sits on the
                  // light panel, so it is dark ink in both themes —
                  // the theme onSurfaceVariant was light grey on
                  // near-white in dark mode.
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: lightOnSurface),
                ),
              ],
            )
                : Column(
              children: [
                Icon(
                  Icons.cancel_rounded,
                  size: 48,
                  // The panel is forced light in both themes, so the
                  // icon uses the light danger token (#B91C1C, 6.47:1
                  // on white) — not the brightness-aware one, whose
                  // dark leg is unreadable on a light panel.
                  color: AppColors.errorText,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.passNotValid,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: lightOnSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.passPickupTarget,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: lightOnSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${DateFormat.yMMMd(locale).format(pickupTime)} • ${DateFormat.Hm(locale).format(pickupTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: lightOnSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

