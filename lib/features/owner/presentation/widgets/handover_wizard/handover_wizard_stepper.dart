import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Item 9 (O26–O30): the 5-step handover stepper — Verify →
/// Payment → Checklist → Photos → Agreement. The same pattern as
/// the add-vehicle stepper (28px circles, a connector line between
/// steps, done steps green semibold, the current step semibold in
/// the step colour).
class HandoverWizardStepperBar extends StatelessWidget {
  final int currentStep;

  const HandoverWizardStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.handoverWizardStepVerify,
      l10n.handoverWizardStepPayment,
      l10n.handoverWizardStepChecklist,
      l10n.handoverWizardStepPhotos,
      l10n.handoverWizardStepAgreement,
    ];
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) _stepperDivider(context, i),
            _stepperItem(context, i + 1, labels[i]),
          ],
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
              color: isDone
                  ? AppColors.accentSuccessStrong
                  : isCurrent
                      ? AppColors.orangeFill
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone
                    ? AppColors.accentSuccessStrong
                    : isCurrent
                        ? AppColors.orangeFill
                        : Theme.of(context).dividerColor,
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
                            color: isCurrent
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight:
                      isDone || isCurrent ? FontWeight.w600 : FontWeight.w500,
                  color: isDone
                      ? AppColors.accentSuccessStrong
                      : isCurrent
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.primaryContainer
                              : Theme.of(context).colorScheme.primary)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _stepperDivider(BuildContext context, int step) {
    final isPassed = currentStep > step;
    return Container(
      width: 12,
      height: 28,
      alignment: Alignment.center,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
            color: isPassed
                ? AppColors.accentSuccessStrong
                : Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(1)),
      ),
    );
  }
}
