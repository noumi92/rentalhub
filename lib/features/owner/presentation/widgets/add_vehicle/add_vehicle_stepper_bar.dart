import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class AddVehicleStepperBar extends StatelessWidget {
  final int currentStep;

  const AddVehicleStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _stepperItem(context, 1, l10n.addVehicleStepperSpecs),
          _stepperDivider(context, 1),
          _stepperItem(context, 2, l10n.addVehicleStepperPhotos),
          _stepperDivider(context, 2),
          _stepperItem(context, 3, l10n.addVehicleStepperRates),
          _stepperDivider(context, 3),
          _stepperItem(context, 4, l10n.addVehicleStepperReview),
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
              color: isDone ? AppColors.accentSuccessStrong : isCurrent ? AppColors.orangeFill : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.accentSuccessStrong : isCurrent ? AppColors.orangeFill : Theme.of(context).dividerColor,
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
                        color: isCurrent ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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
              // Audit §5 (Critical): theme-aware exactly like the
              // onboarding stepper fix — hardcoded AppColors.primary
              // navy was ~1.5:1 on a dark surface. Dark mode uses the
              // pale lavender primaryContainer — NOT
              // colorScheme.primary, which in the dark theme is the
              // dark navy #252B7A (1.46:1, still unreadable).
              color: isCurrent ? (Theme.of(context).brightness == Brightness.dark ? AppColors.primaryContainer : Theme.of(context).colorScheme.primary) : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperDivider(BuildContext context, int step) {
    final isPassed = currentStep > step;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isPassed ? AppColors.accentSuccess : Theme.of(context).dividerColor,
    );
  }
}

