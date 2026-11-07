import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/booking_summary_card.dart';

class BookingApprovedView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onPayAdvance;
  final VoidCallback? onBack;

  const BookingApprovedView({
    super.key,
    required this.booking,
    this.onPayAdvance,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: Text(
                'Booking Approved!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentSuccess.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentSuccess, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ready for Advance Payment',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pay Rs. ${booking.advanceRequired} to guarantee pickup.',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    BookingSummaryCard(
                      carName: booking.vehicleName ?? 'Vehicle',
                      plateNumber: booking.vehiclePlate ?? 'PAK-786',
                      shopName: booking.shopName ?? 'Showroom',
                      isWithDriver: booking.isWithDriver,
                      packageType: booking.packageType,
                      pickupTime: booking.pickupTime,
                      returnTime: booking.returnTime,
                      totalAmount: booking.totalAmount,
                      advanceRequired: booking.advanceRequired,
                      tripType: booking.tripType,
                      kmLimit: booking.kmLimit,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: 'Pay Advance (Rs. ${booking.advanceRequired})',
                icon: Icons.payments_rounded,
                onPressed: () async {
                  onPayAdvance?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

