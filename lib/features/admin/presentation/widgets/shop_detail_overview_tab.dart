import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import 'admin_detail_section.dart';
import 'admin_mini_kpi_strip.dart';
import 'admin_status_chip.dart';
import 'shop_fleet_photos.dart';

/// Top identity header + executive KPI strip for [AdminShopDetailView].
class ShopDetailHeaderKpis extends StatelessWidget {
  const ShopDetailHeaderKpis({
    super.key,
    required this.shop,
    required this.vehicleCount,
    required this.bookingCount,
    required this.creditsBalance,
  });

  final ShopModel shop;
  final int vehicleCount;
  final int bookingCount;
  final int? creditsBalance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final statusLabel = shop.suspended
        ? l10n.admin2_suspended
        : humanizeStatus(shop.verificationStatus, l10n);
    final statusTone = shop.suspended
        ? AdminStatusTone.danger
        : shop.verificationStatus == 'approved' ||
                shop.verificationStatus == 'verified'
            ? AdminStatusTone.success
            : AdminStatusTone.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shop.shopName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            AdminStatusChip(label: statusLabel, tone: statusTone),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.admin2_shopDetailContact(
            shop.city,
            shop.address,
            shop.ownerName ?? '—',
            shop.phoneNumber,
          ),
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (shop.suspended && (shop.suspensionReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.admin2_shopDetailSuspensionReason(shop.suspensionReason ?? ''),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        AdminMiniKpiStrip(items: [
          AdminMiniKpi(
            label: l10n.admin2_shopDetailPlan,
            value: shop.plan.toUpperCase(),
            icon: Icons.card_membership_rounded,
          ),
          AdminMiniKpi(
            label: l10n.admin2_navCars,
            value: '$vehicleCount',
            icon: Icons.directions_car_rounded,
          ),
          AdminMiniKpi(
            label: l10n.admin2_shopDetailLifetimeBookings,
            value: '$bookingCount',
            icon: Icons.receipt_long_rounded,
          ),
          AdminMiniKpi(
            label: l10n.admin2_shopDetailRating,
            value: shop.hasRealRating ? shop.rating.toStringAsFixed(1) : '—',
            icon: Icons.star_rounded,
          ),
          AdminMiniKpi(
            label: l10n.adminAuditCredits,
            value: creditsBalance == null
                ? l10n.adminAuditCreditsNone
                : '$creditsBalance',
            icon: Icons.chat_rounded,
          ),
        ]),
      ],
    );
  }
}

/// Overview tab inside [AdminShopDetailView]: payout accounts & quick links.
class ShopDetailOverviewTab extends StatelessWidget {
  const ShopDetailOverviewTab({
    super.key,
    required this.shop,
    required this.padding,
    required this.onViewCars,
    this.onViewBookings,
  });

  final ShopModel shop;
  final EdgeInsetsGeometry padding;
  final VoidCallback onViewCars;
  final VoidCallback? onViewBookings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                key: const Key('admin2_shopDetailViewCars'),
                onPressed: onViewCars,
                child: Text(l10n.admin2_shopDetailViewCars),
              ),
              if (onViewBookings != null)
                FilledButton(
                  key: const Key('admin2_shopDetailViewBookings'),
                  onPressed: onViewBookings,
                  child: Text(l10n.admin2_shopDetailViewBookings),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AdminDetailSection(
            title: l10n.admin2_shopDetailBankAccounts,
            lines: shop.bankAccounts.isEmpty
                ? [l10n.admin2_shopDetailNoneOnFile]
                : shop.bankAccounts
                    .map((a) =>
                        '${a['type'] ?? l10n.admin2_shopDetailAccountType} — ${a['title'] ?? a['account'] ?? ''}')
                    .toList(),
          ),
          AdminDetailSection(
            title: l10n.admin2_shopDetailKycDocs,
            lines: shop.kycDocuments.isEmpty
                ? [l10n.admin2_shopDetailNoneUploaded]
                : shop.kycDocuments.keys.toList(),
          ),
        ],
      ),
    );
  }
}

/// KYC & Docs tab inside [AdminShopDetailView]: checklist, docs, fleet photos,
/// and application review action.
class ShopDetailKycTab extends StatelessWidget {
  const ShopDetailKycTab({
    super.key,
    required this.shop,
    required this.padding,
    required this.onReviewApplication,
  });

  final ShopModel shop;
  final EdgeInsetsGeometry padding;
  final VoidCallback onReviewApplication;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final checklist = ShopApplicationChecklist.fromShop(shop, l10n);
    final brightness = Theme.of(context).brightness;
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.admin2_shopAppChecklist(checklist.doneCount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onReviewApplication,
                icon: const Icon(Icons.verified_user_rounded, size: 16),
                label: Text(l10n.admin2_shopDetailReviewApplication),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in checklist.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    item.done
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 18,
                    color: item.done
                        ? AppColors.successTextFor(brightness)
                        : AppColors.warningTextFor(brightness),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.label)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          AdminDetailSection(
            title: l10n.admin2_shopDetailKycDocs,
            lines: shop.kycDocuments.isEmpty
                ? [l10n.admin2_shopDetailNoneUploaded]
                : shop.kycDocuments.keys.toList(),
          ),
          if (shop.fleetPhotos.isNotEmpty) ...[
            Text(
              l10n.admin2_shopAppFleetPhotos,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ShopFleetPhotos(photoUrls: shop.fleetPhotos),
          ],
        ],
      ),
    );
  }
}
