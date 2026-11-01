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
      backgroundColor: AppColors.backgroundLight,
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
              titleWidget: const Text(
                'Booking Approved!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
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
                          colors: [AppColors.midnightNavy, AppColors.royalNavy],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                color: AppColors.emeraldGreen, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ready for Advance Payment',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lock reserved for next 2 hours. Pay Rs. ${booking.advanceRequired} to guarantee pickup.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLavender,
                                  ),
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
