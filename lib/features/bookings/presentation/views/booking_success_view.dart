import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';

class BookingSuccessView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onProceedToPayment;
  final VoidCallback? onViewBookings;

  const BookingSuccessView({
    super.key,
    required this.booking,
    this.onProceedToPayment,
    this.onViewBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const CustomCurvedHeader(
              height: 100,
              titleWidget: Text(
                'Request Transmitted',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                AppColors.emeraldGreen.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: AppColors.emeraldGreen, size: 54),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Request Sent Successfully!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnightNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reference: ${booking.bookingId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sunsetOrange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your reservation request for ${booking.vehicleName ?? "Vehicle"} has been delivered to ${booking.shopName ?? "the showroom"}. Once approved, you will be notified to submit the advance deposit.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Showroom Status:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.amberGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Pending Review',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.amberGold)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Advance Due Upon Approval:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                              Text('Rs. ${booking.advanceRequired}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.sunsetOrange)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Opening WhatsApp with showroom for ${booking.bookingId}...'),
                            backgroundColor: AppColors.emeraldGreen,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emeraldGreen,
                        side: const BorderSide(color: Color(0xFF86EFAC)),
                        backgroundColor: const Color(0xFFF0FDF4),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.emeraldGreen),
                      label: const Text('Message Showroom on WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DebouncedButton(
                    text: 'View Payment Details / Status',
                    icon: Icons.payments_outlined,
                    onPressed: () async {
                      onProceedToPayment?.call();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onViewBookings,
                    child: const Text('Return to My Bookings',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.royalNavy)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

