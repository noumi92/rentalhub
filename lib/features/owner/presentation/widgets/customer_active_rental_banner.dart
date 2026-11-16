import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// Showroom redesign Phase 3 — the mint active-rental banner on an
/// expanded customer row. Selects from the bookings already loaded
/// for the row ([CustomerSummary.bookings]); no new fetch. Renders
/// nothing when there is no active booking.
List<BookingEntity> selectActiveBookings(List<BookingEntity> bookings) =>
    bookings.where((b) => b.status == 'active').toList();

class CustomerActiveRentalBanner extends StatelessWidget {
  const CustomerActiveRentalBanner({super.key, required this.bookings});

  final List<BookingEntity> bookings;

  @override
  Widget build(BuildContext context) {
    final active = selectActiveBookings(bookings);
    if (active.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successContainerFor(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successBorderFor(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_rounded,
                  size: 18, color: AppColors.successOnContainerFor(brightness)),
              const SizedBox(width: 6),
              Text(l10n.activeRentals,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.successOnContainerFor(brightness))),
            ],
          ),
          const SizedBox(height: 8),
          for (final b in active)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${b.vehicleName ?? l10n.summaryVehicle} • ${formatDate(context, b.pickupTime)} – ${formatDate(context, b.returnTime)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color:
                              AppColors.successOnContainerFor(brightness)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.amountRs(formatRs(b.totalAmount)),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              AppColors.successOnContainerFor(brightness))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
