import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../owner/presentation/services/subscription_plans.dart';
import '../../data/datasources/admin_packages_data_source.dart';
import 'admin_mini_kpi_strip.dart';
import 'admin_status_chip.dart';

/// Displays all shops with their current subscription tier and WhatsApp
/// credit balance, with quick buttons for Super Admin / Operations to
/// change a shop's plan or adjust its WhatsApp credits.
class AdminShopPlansTab extends StatelessWidget {
  const AdminShopPlansTab({
    super.key,
    required this.shops,
    required this.canManage,
    required this.onChangePlan,
    required this.onGrantCredits,
  });

  final List<AdminShopPlanRow> shops;
  final bool canManage;
  final ValueChanged<AdminShopPlanRow> onChangePlan;
  final ValueChanged<AdminShopPlanRow> onGrantCredits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogStrip = AdminMiniKpiStrip(
      items: [
        for (final p in subscriptionPlans)
          AdminMiniKpi(
            label:
                '${p.id.toUpperCase()} (${p.carLimit == null ? '∞' : '${p.carLimit} cars'})',
            value: p.id == 'free'
                ? 'Active'
                : 'Rs. ${formatRs(p.monthlyPrice)} · ${l10n?.packagesComingSoonBadge ?? 'Coming Soon'}',
            icon: Icons.card_membership_rounded,
            muted: p.id != 'free',
          ),
      ],
    );
    if (shops.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          catalogStrip,
          Expanded(
            child: AppEmptyState(
              title: l10n?.adminPackagesNoShops ?? 'No shops found.',
              icon: Icons.store_rounded,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        catalogStrip,
        Expanded(
          child: ListView.separated(
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
        final shop = shops[i];
        final tone = switch (shop.tier) {
          'business' || 'enterprise' => AdminStatusTone.success,
          'pro' => AdminStatusTone.info,
          _ => AdminStatusTone.neutral,
        };
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop.shopName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AdminStatusChip(
                      label: shop.tier.toUpperCase(),
                      tone: tone,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${shop.city.isEmpty ? '—' : shop.city} • WhatsApp: ${shop.whatsappBalance} credits',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onChangePlan(shop),
                        icon: const Icon(Icons.card_membership_rounded, size: 16),
                        label: Text(
                          l10n?.adminPackagesChangePlan ?? 'Change Plan',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onGrantCredits(shop),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: Text(
                          l10n?.adminPackagesGrantCredits ?? 'Grant Credits',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
          ),
        ),
      ],
    );
  }
}
