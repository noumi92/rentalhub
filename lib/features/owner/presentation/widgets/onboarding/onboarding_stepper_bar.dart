import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class OnboardingStepperBar extends StatelessWidget {
  final int currentStep;

  const OnboardingStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          _stepPill(context, 1, 'Shop Details', Icons.storefront_rounded),
          _stepLine(context, 1),
          _stepPill(context, 2, 'Location', Icons.location_on_rounded),
          _stepLine(context, 2),
          _stepPill(context, 3, 'Payouts', Icons.account_balance_wallet_rounded),
          _stepLine(context, 3),
          _stepPill(context, 4, 'KYC Docs', Icons.verified_user_rounded),
        ],
      ),
    );
  }

  Widget _stepPill(BuildContext context, int step, String label, IconData icon) {
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
                color: isDone ? AppColors.accentSuccess : isCurrent ? AppColors.secondary : Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              size: 16,
              color: isDone || isCurrent ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isCurrent ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _stepLine(BuildContext context, int step) {
    final isPassed = currentStep > step;
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isPassed ? AppColors.accentSuccess : Theme.of(context).dividerColor,
    );
  }
}

