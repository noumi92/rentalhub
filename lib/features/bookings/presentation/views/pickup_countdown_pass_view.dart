import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/digital_qr_pass_widget.dart';
import '../widgets/pickup_countdown_timer.dart';

class PickupCountdownPassView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onReturnHome;
  final VoidCallback? onBack;

  const PickupCountdownPassView({
    super.key,
    required this.booking,
    this.onReturnHome,
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
                'Pickup Countdown Pass',
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
                    PickupCountdownTimer(
                      targetPickupTime: booking.pickupTime,
                    ),
                    const SizedBox(height: 16),
                    DigitalQrPassWidget(
                      bookingId: booking.bookingId,
                      vehicleName: booking.vehicleName ?? 'Rental Vehicle',
                      plateNumber: booking.vehiclePlate ?? 'PAK-786',
                      shopName: booking.shopName ?? 'Rental Showroom',
                      pickupTime: booking.pickupTime,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.location_on_rounded,
                                  color: AppColors.sunsetOrange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Showroom Handover Point',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.midnightNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${booking.shopName ?? "Al-Falah Rent a Car"}, Main Boulevard, Gulberg III, Lahore',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Calling showroom...'),
                                        backgroundColor: AppColors.royalNavy,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.royalNavy,
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.call_rounded, size: 16),
                                  label: const Text('Call Shop'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Opening Google Maps...'),
                                        backgroundColor: AppColors.emeraldGreen,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.emeraldGreen,
                                    side: const BorderSide(color: Color(0xFF86EFAC)),
                                    backgroundColor: const Color(0xFFF0FDF4),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.directions_rounded, size: 16),
                                  label: const Text('Directions'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                text: 'Done • Back to Home',
                icon: Icons.home_rounded,
                onPressed: () async {
                  onReturnHome?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
