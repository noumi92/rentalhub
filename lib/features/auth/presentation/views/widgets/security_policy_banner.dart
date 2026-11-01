import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class SecurityPolicyBanner extends StatelessWidget {
  final String message;
  final IconData icon;

  const SecurityPolicyBanner({
    super.key,
    required this.message,
    this.icon = Icons.lock_clock_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.amberGold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.amberGold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.midnightNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

