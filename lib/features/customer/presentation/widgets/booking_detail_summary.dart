import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// Phase A (A1): the booking summary section of the customer booking
/// detail screen, extracted so the view stays under the 250-line cap.
class BookingDetailSummary extends StatelessWidget {
  const BookingDetailSummary({super.key, required this.booking});

  final BookingEntity booking;

  // CU-m4: locale dates — the old hand-rolled day/month/year + AM/PM
  // ignored the Urdu locale.
  String _formatDateTime(BuildContext context, DateTime d) {
    final locale = Localizations.localeOf(context).languageCode;
    return '${DateFormat.yMMMd(locale).format(d)}  ${DateFormat.jm(locale).format(d)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = booking;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        children: [
          _row(context, l10n.summaryVehicle, b.vehicleName ?? '—'),
          _row(context, l10n.summaryPlate, b.vehiclePlate ?? '—'),
          _row(context, l10n.packageLabel, b.packageType),
          _row(context, l10n.summaryDriveMode, b.isWithDriver ? l10n.summaryWithDriver : l10n.summarySelfDrive),
          _row(context, l10n.summaryTrip, b.tripType == 'out_city' ? l10n.outOfCity : l10n.inCity),
          if (b.fixedRouteSummary != null && b.fixedRouteSummary!.isNotEmpty)
            _row(context, l10n.outCityFixedRouteLabel, b.fixedRouteSummary!),
          _row(context, l10n.pickupLabel, _formatDateTime(context, b.pickupTime)),
          _row(context, l10n.summaryReturn, _formatDateTime(context, b.returnTime)),
          const Divider(height: 18),
          _row(context, l10n.summaryTotal, l10n.amountRs(formatRs(b.totalAmount)), bold: true),
          _row(context, l10n.summaryAdvanceRequired, l10n.amountRs(formatRs(b.advanceRequired))),
          _row(context, l10n.summaryAdvancePaid, l10n.amountRs(formatRs(b.advancePaid))),
          _row(context, l10n.summaryRemaining, l10n.amountRs(formatRs(b.remainingBalance)), bold: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // CU-m5: Flexible + ellipsis — a long label or value wraps
          // instead of overflowing at large text scale.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // CU-m1: the hardcoded 13px drifted from the type scale.
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The shop's rejection reason, shown on the detail screen when the
/// request was rejected — or when a payment proof was rejected (the
/// booking then sits back at 'approved' with the reason attached, and
/// the customer needs to know why before uploading again).
class BookingDetailRejectionCard extends StatelessWidget {
  const BookingDetailRejectionCard({
    super.key,
    required this.reason,
    this.prefix,
  });

  final String reason;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentDanger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentDanger.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${prefix ?? l10n.summaryDeclinedPrefix}$reason',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A plain informational note (for example: proof submitted, waiting for
/// the shop to verify).
class BookingDetailInfoCard extends StatelessWidget {
  const BookingDetailInfoCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
