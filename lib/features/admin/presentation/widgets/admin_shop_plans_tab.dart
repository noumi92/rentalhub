import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../owner/presentation/services/subscription_plans.dart';
import '../../data/datasources/admin_packages_data_source.dart';
import 'admin_mini_kpi_strip.dart';
import 'admin_status_chip.dart';

/// Displays all shops with their current subscription tier and WhatsApp
/// credit balance. During initial launch, Change Plan and Grant Credits
/// are shown as Coming Soon.
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
    final comingSoon = l10n?.packagesComingSoonBadge ?? 'Coming Soon';
    final scheme = Theme.of(context).colorScheme;

    final catalogStrip = AdminMiniKpiStrip(
      items: [
        for (final p in subscriptionPlans)
          AdminMiniKpi(
            label:
                '${p.id.toUpperCase()} (${p.carLimit == null ? '∞' : '${p.carLimit} cars'})',
            value: p.id == 'free'
                ? 'Active'
                : 'Rs. ${formatRs(p.monthlyPrice)} · $comingSoon',
            icon: Icons.card_membership_rounded,
            muted: p.id != 'free',
          ),
      ],
    );

    final comingSoonCard = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n?.adminPackagesChangePlan ?? 'Change Plan'} & ${l10n?.adminPackagesGrantCredits ?? 'Grant Credits'} — $comingSoon',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.adminPackagesControlsComingSoon ??
                      'Plan changes and credit grants are coming soon during the initial launch phase.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (shops.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          catalogStrip,
          comingSoonCard,
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
        comingSoonCard,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
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
