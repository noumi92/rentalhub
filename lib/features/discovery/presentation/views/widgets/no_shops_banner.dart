import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// B2: the empty state shown on the customer map when no verified shop is
/// within the selected radius.
class NoShopsBanner extends StatelessWidget {
  const NoShopsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        'No verified showrooms within this radius yet. Try a wider radius.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }
}
