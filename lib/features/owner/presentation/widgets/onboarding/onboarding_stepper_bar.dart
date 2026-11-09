import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';

class OnboardingStepperBar extends StatelessWidget {
  final int currentStep;

  const OnboardingStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          _stepPill(context, 1, l10n.onboardingStepShopDetails, Icons.storefront_rounded),
          _stepLine(context, 1),
          _stepPill(context, 2, l10n.onboardingStepLocation, Icons.location_on_rounded),
          _stepLine(context, 2),
          _stepPill(context, 3, l10n.onboardingStepPayouts, Icons.account_balance_wallet_rounded),
          _stepLine(context, 3),
          _stepPill(context, 4, l10n.onboardingStepKyc, Icons.verified_user_rounded),
          _stepLine(context, 4),
          _stepPill(context, 5, l10n.onboardingStepReview, Icons.fact_check_rounded),
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
              // Audit §1: white on accentSuccess #10B981 is ~2.5:1;
              // accentSuccessStrong #047857 is 5.48:1 with white.
              color: isDone ? AppColors.accentSuccessStrong : isCurrent ? AppColors.orangeFill : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.accentSuccessStrong : isCurrent ? AppColors.orangeFill : Theme.of(context).dividerColor,
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
            textAlign: TextAlign.center,
            style: TextStyle(
              // Audit §1: 10sp is below the §4.5 minimum (11sp) and
              // maxLines 1 truncated Urdu labels — allow 2 lines.
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              // #10: theme-aware — the hardcoded AppColors.primary navy
              // was ~1.2:1 on a dark surface (invisible). Light mode
              // keeps the theme primary; dark mode uses the pale
              // lavender primaryContainer — NOT colorScheme.primary,
              // which in the dark theme is the dark navy #252B7A
              // (1.46:1 on the dark surface, still unreadable).
              color: isCurrent ? (Theme.of(context).brightness == Brightness.dark ? AppColors.primaryContainer : Theme.of(context).colorScheme.primary) : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
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

