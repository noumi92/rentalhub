import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/theme/card_decoration.dart';

class SubscriptionTierCard extends StatelessWidget {
  final String title;
  final int pricePkr;
  final String billingPeriod;
  final List<String> features;
  final bool isCurrent;
  final bool isPopular;
  final bool isPending;
  final bool isComingSoon;
  final bool showActionButton;
  final VoidCallback onSelect;

  const SubscriptionTierCard({
    super.key,
    required this.title,
    required this.pricePkr,
    required this.billingPeriod,
    required this.features,
    this.isCurrent = false,
    this.isPopular = false,
    this.isPending = false,
    this.isComingSoon = false,
    this.showActionButton = true,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: (isPopular || isCurrent)
            ? Border.all(
                color: isPopular
                    ? AppColors.secondary
                    : AppColors.accentSuccess,
                width: 2,
              )
            : null,
        boxShadow: AppCardDecoration.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (isComingSoon) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.packagesComingSoonBadge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ] else if (isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.orangeFill, borderRadius: BorderRadius.circular(6)),
                  child: Text(l10n.subscriptionMostPopular, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ] else if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.accentSuccessStrong, borderRadius: BorderRadius.circular(6)),
                  child: Text(l10n.subscriptionCurrentPlan, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 4,
            runSpacing: 2,
            children: [
              Text(l10n.amountRs(formatRs(pricePkr)), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(billingPeriod, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Divider(height: 20),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.successTextFor(Theme.of(context).brightness)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              )),
          if (showActionButton) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isCurrent || isPending) ? null : onSelect,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: isPopular ? AppColors.orangeFill : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isCurrent
                      ? l10n.subscriptionActivePlan
                      : isPending
                          ? l10n.subscriptionRequested
                          : l10n.subscriptionUpgradeTo(title),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

