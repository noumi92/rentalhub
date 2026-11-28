import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/card_decoration.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/whatsapp_credits_models.dart';

/// Shared read-only preview of all defined WhatsApp credit packages
/// (Bronze, Silver, Gold) with Coming Soon badges and monthly plan allowances.
class WhatsappPackagesPreviewList extends StatelessWidget {
  const WhatsappPackagesPreviewList({
    super.key,
    this.tier = 'free',
  });

  final String tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...whatsappCreditPacks.map((pack) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
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
                            '${pack.name} · ${pack.credits} ${l10n.creditsTitle}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.packagesComingSoonBadge,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.amountRs(formatRs(pack.price))} · ${l10n.amountRs(pack.perMessage)} ${l10n.creditsPerMessage}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 4),
        Text(
          l10n.creditsFreeMonthly,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(l10n.creditsFreePlanFree,
            style: Theme.of(context).textTheme.bodyMedium),
        Text(l10n.creditsFreePlanPro,
            style: Theme.of(context).textTheme.bodyMedium),
        Text(l10n.creditsFreePlanBusiness,
            style: Theme.of(context).textTheme.bodyMedium),
        Text(
          '${l10n.creditsFreeLabel}: ${freeMonthlyCreditsForTier(tier)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
