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
        border: Border.all(color: AppColors.borderSubtle),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                  Text(
                    shopName,
                    style: Theme.of(context).textTheme.bodySmall,
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
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            size: 110, color: AppColors.primary),
                        Text(
                          bookingId,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Present this QR Code to showroom staff at handover',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pickup Target:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${pickupTime.day}/${pickupTime.month}/${pickupTime.year} • ${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

