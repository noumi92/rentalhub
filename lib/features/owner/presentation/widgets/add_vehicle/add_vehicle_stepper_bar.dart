import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class AddVehicleStepperBar extends StatelessWidget {
  final int currentStep;

  const AddVehicleStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _stepperItem(1, 'Vehicle Specs'),
          _stepperDivider(1),
          _stepperItem(2, 'Photos & Docs'),
          _stepperDivider(2),
          _stepperItem(3, 'Rates & Policy'),
          _stepperDivider(3),
          _stepperItem(4, 'Review'),
        ],
      ),
    );
  }

  Widget _stepperItem(int step, String label) {
    final isDone = currentStep > step;
    final isCurrent = currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone ? AppColors.emeraldGreen : isCurrent ? AppColors.sunsetOrange : AppColors.backgroundLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.emeraldGreen : isCurrent ? AppColors.sunsetOrange : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$step',
                      style: TextStyle(
                        fontSize: 12,
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
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isCurrent ? AppColors.midnightNavy : AppColors.textMuted,
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
      color: isPassed ? AppColors.emeraldGreen : AppColors.border,
    );
  }
}

