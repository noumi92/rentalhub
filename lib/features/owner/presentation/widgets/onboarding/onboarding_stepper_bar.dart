import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class OnboardingStepperBar extends StatelessWidget {
  final int currentStep;

  const OnboardingStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          _stepPill(1, 'Shop Details', Icons.storefront_rounded),
          _stepLine(1),
          _stepPill(2, 'Location', Icons.location_on_rounded),
          _stepLine(2),
          _stepPill(3, 'Payouts', Icons.account_balance_wallet_rounded),
          _stepLine(3),
          _stepPill(4, 'KYC Docs', Icons.verified_user_rounded),
        ],
      ),
    );
  }

  Widget _stepPill(int step, String label, IconData icon) {
    final isDone = currentStep > step;
    final isCurrent = currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone ? AppColors.accentSuccess : isCurrent ? AppColors.secondary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.accentSuccess : isCurrent ? AppColors.secondary : AppColors.borderSubtle,
                width: 1.5,
              ),
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              size: 16,
              color: isDone || isCurrent ? Colors.white : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isCurrent ? AppColors.primary : AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _stepLine(int step) {
    final isPassed = currentStep > step;
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isPassed ? AppColors.accentSuccess : AppColors.borderSubtle,
    );
  }
}

