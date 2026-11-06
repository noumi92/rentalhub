import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// E1: one of the dashboard's quick-service tiles (Explore Shops,
/// My Bookings, KYC Docs). Extracted from [CustomerDashboardView] so the
/// view stays under the 250-line cap.
class CustomerServiceButton extends StatelessWidget {
  const CustomerServiceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.midnightNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
