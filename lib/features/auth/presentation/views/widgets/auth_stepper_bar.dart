import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class AuthStepperBar extends StatelessWidget {
  final int currentStep; // 1 or 2

  const AuthStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: _stepPill(
              context,
              step: 1,
              title: l10n?.stepperProfile ?? '1. Profile Info',
              isDone: currentStep > 1,
              isCurrent: currentStep == 1,
              icon: Icons.person_rounded,
            ),
          ),
          Container(
            width: 20,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: currentStep > 1 ? AppColors.accentSuccess : Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _stepPill(
              context,
              step: 2,
              title: l10n?.stepperRole ?? '2. Select Role',
              isDone: false,
              isCurrent: currentStep == 2,
              icon: Icons.verified_user_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepPill(
    BuildContext context, {
    required int step,
    required String title,
    required bool isDone,
    required bool isCurrent,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Audit 2026-11-15 AC-2: copied from the onboarding stepper
    // verbatim — done accentSuccessStrong (white check 5.48:1),
    // current orangeFill (white icon 5.18:1). The old done
    // accentSuccess (2.54:1) and current secondary (3.29:1) failed.
    final color = isDone
        ? AppColors.accentSuccessStrong
        : isCurrent
            ? AppColors.orangeFill
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isCurrent ? color : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : Icon(
                    icon,
                    size: 13,
                    color: isCurrent ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            // Audit 2026-11-15 AC-2: Urdu labels truncated at
            // maxLines 1 — allow 2, like the onboarding stepper.
            // (Phone check still owed: truncation is UNVERIFIED live.)
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              // The hardcoded AppColors.primary navy was 1.18:1 on
              // the dark surface (invisible). Light keeps the theme
              // primary; dark uses the pale lavender primaryContainer.
              color: isCurrent ? (isDark ? AppColors.primaryContainer : Theme.of(context).colorScheme.primary) : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

