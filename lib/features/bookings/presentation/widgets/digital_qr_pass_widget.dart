import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';

class DigitalQrPassWidget extends StatelessWidget {
  final String bookingId;
  final String vehicleName;
  final String plateNumber;
  final String shopName;
  final DateTime pickupTime;

  const DigitalQrPassWidget({
    super.key,
    required this.bookingId,
    required this.vehicleName,
    required this.plateNumber,
    required this.shopName,
    required this.pickupTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
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
                  color: AppColors.royalNavy.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            size: 110, color: AppColors.midnightNavy),
                        Text(
                          bookingId,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.royalNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Present this QR Code to showroom staff at handover',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pickup Target:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '${pickupTime.day}/${pickupTime.month}/${pickupTime.year} • ${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.midnightNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
