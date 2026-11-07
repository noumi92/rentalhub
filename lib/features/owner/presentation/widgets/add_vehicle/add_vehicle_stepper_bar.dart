import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class AddVehicleStepperBar extends StatelessWidget {
  final int currentStep;

  const AddVehicleStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _stepperItem(context, 1, 'Vehicle Specs'),
          _stepperDivider(1),
          _stepperItem(context, 2, 'Photos & Docs'),
          _stepperDivider(2),
          _stepperItem(context, 3, 'Rates & Policy'),
          _stepperDivider(3),
          _stepperItem(context, 4, 'Review'),
        ],
      ),
    );
  }

  Widget _stepperItem(BuildContext context, int step, String label) {
    final isDone = currentStep > step;
    final isCurrent = currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone ? AppColors.accentSuccess : isCurrent ? AppColors.secondary : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.accentSuccess : isCurrent ? AppColors.secondary : AppColors.borderSubtle,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$step',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isCurrent ? Colors.white : AppColors.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isCurrent ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperDivider(int step) {
    final isPassed = currentStep > step;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isPassed ? AppColors.accentSuccess : AppColors.borderSubtle,
    );
  }
}

