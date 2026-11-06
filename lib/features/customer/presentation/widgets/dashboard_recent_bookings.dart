import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// E1: the dashboard's "Recent Activity" section — the loading spinner,
/// the empty state, or the three most recent bookings. Extracted from
/// [CustomerDashboardView] so the view stays under the 250-line cap.
class DashboardRecentBookings extends StatelessWidget {
  const DashboardRecentBookings({
    super.key,
    required this.isLoading,
    required this.bookings,
    this.onViewAll,
    this.onOpenBooking,
    this.onExploreShops,
  });

  final bool isLoading;
  final List<BookingEntity> bookings;
  final VoidCallback? onViewAll;
  final Function(BookingEntity booking)? onOpenBooking;
  final VoidCallback? onExploreShops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.midnightNavy,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sunsetOrange)),
            ),
          ],
        ),
        if (isLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.car_rental_outlined,
                      size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  const Text('No bookings found yet.',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: onExploreShops,
                    child: const Text('Discover Nearby Cars'),
                  ),
                ],
              ),
            ),
          )
        else
          ...bookings.take(3).map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  leading: const Icon(Icons.directions_car_rounded,
                      color: AppColors.royalNavy),
                  title: Text(b.vehicleName ?? 'Rental Car',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle:
                      Text('${b.status.toUpperCase()} • Rs. ${b.totalAmount}'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14),
                  onTap: () => onOpenBooking?.call(b),
                ),
              )),
      ],
    );
  }
}
