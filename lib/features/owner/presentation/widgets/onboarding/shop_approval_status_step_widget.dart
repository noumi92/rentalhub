import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ShopApprovalStatusStepWidget extends StatelessWidget {
  final VoidCallback onGoToFleet;

  const ShopApprovalStatusStepWidget({
    super.key,
    required this.onGoToFleet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFF0FDF4),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_circle_rounded, size: 64, color: AppColors.emeraldGreen),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Shop Application Submitted!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.midnightNavy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your shop profile and KYC credentials have been routed to the Super Admin desk. You will receive SMS & WhatsApp verification within 2 to 4 business hours.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.sunsetOrange, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet Catalog Ready', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                    SizedBox(height: 2),
                    Text(
                      'You can start adding your cars, setting 1h/3h/6h/24h rates and photos right now.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onGoToFleet,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Manage Fleet & Add Vehicles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sunsetOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

