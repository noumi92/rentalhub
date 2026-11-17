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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontWeight: FontWeight.w500,
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
              fontWeight: isDone || isCurrent ? FontWeight.w600 : FontWeight.w500,
              // Done steps read green so the completed road stands
              // out; the current step keeps its pinned primary
              // treatment (dark: pale lavender primaryContainer —
              // see the comment below).
              color: isDone
                  ? AppColors.accentSuccessStrong
                  : isCurrent
                      ? (Theme.of(context).brightness == Brightness.dark ? AppColors.primaryContainer : Theme.of(context).colorScheme.primary)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Connector line between two steps. The box is the 28px circle
  /// height with the 2px line centred in it, so the line sits at
  /// the circle centre (the old bottom-margin-16 version floated
  /// ~16px below the circles). Green — the same strong green as
  /// the done circles — once the step on its left is passed.
  Widget _stepperDivider(BuildContext context, int step) {
    final isPassed = currentStep > step;
    return Container(
      width: 24,
      height: 28,
      alignment: Alignment.center,
      child: Container(
        height: 2,
        decoration: BoxDecoration(color: isPassed ? AppColors.accentSuccessStrong : Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(1)),
      ),
    );
  }
}

