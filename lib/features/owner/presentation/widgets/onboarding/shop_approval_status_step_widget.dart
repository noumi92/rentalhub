import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';

class ShopApprovalStatusStepWidget extends StatelessWidget {
  final VoidCallback onGoToFleet;

  const ShopApprovalStatusStepWidget({
    super.key,
    required this.onGoToFleet,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.successContainerFor(Theme.of(context).brightness),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(Icons.check_circle_rounded, size: 64, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.onboardingApprovalTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingApprovalMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.secondary, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.onboardingFleetReady, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text(
                      l10n.onboardingFleetReadyHint,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onGoToFleet,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(l10n.onboardingManageFleet, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

