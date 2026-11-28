import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_package_catalog_data_source.dart';
import 'admin_status_chip.dart';

/// Admin Package Catalog tab: allows creating, modifying, and deleting both
/// Shop Subscription Packages and WhatsApp Credit Packages.
class AdminPackageCatalogTab extends StatelessWidget {
  const AdminPackageCatalogTab({
    super.key,
    required this.shopPackages,
    required this.whatsappPackages,
    required this.canManage,
    required this.onCreateShopPackage,
    required this.onEditShopPackage,
    required this.onDeleteShopPackage,
    required this.onCreateWhatsappPackage,
    required this.onEditWhatsappPackage,
    required this.onDeleteWhatsappPackage,
  });

  final List<AdminShopPackage> shopPackages;
  final List<AdminWhatsappPackage> whatsappPackages;
  final bool canManage;
  final VoidCallback onCreateShopPackage;
  final ValueChanged<AdminShopPackage> onEditShopPackage;
  final ValueChanged<AdminShopPackage> onDeleteShopPackage;
  final VoidCallback onCreateWhatsappPackage;
  final ValueChanged<AdminWhatsappPackage> onEditWhatsappPackage;
  final ValueChanged<AdminWhatsappPackage> onDeleteWhatsappPackage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        _sectionHeader(
          context,
          title: l10n?.adminShopPackagesSection ?? 'Shop Subscription Packages',
          buttonLabel: l10n?.adminCreateShopPackage ?? 'New Shop Package',
          buttonKey: const ValueKey('admin_create_shop_package_btn'),
          onAdd: canManage ? onCreateShopPackage : null,
        ),
        const SizedBox(height: 10),
        for (final pkg in shopPackages) _shopPackageCard(context, l10n, pkg),
        const SizedBox(height: 20),
        _sectionHeader(
          context,
          title:
              l10n?.adminWhatsappPackagesSection ?? 'WhatsApp Credit Packages',
          buttonLabel:
              l10n?.adminCreateWhatsappPackage ?? 'New WhatsApp Pack',
          buttonKey: const ValueKey('admin_create_wa_package_btn'),
          onAdd: canManage ? onCreateWhatsappPackage : null,
        ),
        const SizedBox(height: 10),
        for (final pkg in whatsappPackages) _waPackageCard(context, l10n, pkg),
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required String buttonLabel,
    required Key buttonKey,
    VoidCallback? onAdd,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (onAdd != null)
          FilledButton.icon(
            key: buttonKey,
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(buttonLabel),
          ),
      ],
    );
  }

  Widget _shopPackageCard(
    BuildContext context,
    AppLocalizations? l10n,
    AdminShopPackage pkg,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final carLabel = pkg.carLimit == null
        ? (l10n?.adminPackageUnlimited ?? 'Unlimited cars')
        : '${pkg.carLimit} cars';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? cs.outlineVariant : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              AdminStatusChip(
                label: pkg.isActive
                    ? (l10n?.active ?? 'Active')
                    : (l10n?.adminPackageInactive ?? 'Inactive'),
                tone: pkg.isActive
                    ? AdminStatusTone.success
                    : AdminStatusTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Rs. ${formatRs(pkg.monthlyPrice)}/mo • Rs. ${formatRs(pkg.yearlyPrice)}/yr',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$carLabel • ${pkg.staffLimit} staff • ${pkg.freeMonthlyCredits} free WA credits/mo',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (canManage) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('edit_shop_pkg_${pkg.id}'),
                  onPressed: () => onEditShopPackage(pkg),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n?.customerDetailEdit ?? 'Edit'),
                ),
                TextButton.icon(
                  key: ValueKey('delete_shop_pkg_${pkg.id}'),
                  onPressed: () => onDeleteShopPackage(pkg),
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(l10n?.financeCategoriesDelete ?? 'Delete'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _waPackageCard(
    BuildContext context,
    AppLocalizations? l10n,
    AdminWhatsappPackage pkg,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? cs.outlineVariant : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (pkg.bestValue) ...[
                AdminStatusChip(
                  label: l10n?.adminPackageBestValue ?? 'Best Value',
                  tone: AdminStatusTone.warning,
                ),
                const SizedBox(width: 6),
              ],
              AdminStatusChip(
                label: pkg.isActive
                    ? (l10n?.active ?? 'Active')
                    : (l10n?.adminPackageInactive ?? 'Inactive'),
                tone: pkg.isActive
                    ? AdminStatusTone.success
                    : AdminStatusTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${pkg.credits} credits • Rs. ${formatRs(pkg.price)} (Rs. ${pkg.perMessage}/msg)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          if (canManage) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('edit_wa_pkg_${pkg.id}'),
                  onPressed: () => onEditWhatsappPackage(pkg),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n?.customerDetailEdit ?? 'Edit'),
                ),
                TextButton.icon(
                  key: ValueKey('delete_wa_pkg_${pkg.id}'),
                  onPressed: () => onDeleteWhatsappPackage(pkg),
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(l10n?.financeCategoriesDelete ?? 'Delete'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
