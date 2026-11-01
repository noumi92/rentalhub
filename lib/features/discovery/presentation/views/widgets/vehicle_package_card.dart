import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class VehiclePackageCard extends StatelessWidget {
  final String title;
  final String urdu;
  final int price;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const VehiclePackageCard({
    super.key,
    required this.title,
    required this.urdu,
    required this.price,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sunsetOrange.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sunsetOrange : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.sunsetOrange.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.sunsetOrange : AppColors.midnightNavy,
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.sunsetOrange,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppColors.sunsetOrange : AppColors.midnightNavy,
              ),
            ),
            Text(
              urdu,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rs. $price',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.midnightNavy,
              ),
            ),
            const Text(
              '/ per day',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

