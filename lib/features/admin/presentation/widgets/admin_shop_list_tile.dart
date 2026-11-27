import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../discovery/data/models/shop_model.dart';
import 'admin_list_card.dart';
import 'admin_status_chip.dart';

/// Phase 3 (3.1) — one row of the shops list, extracted from
/// [AdminShopsView] so the view stays under the 250-line cap with
/// its pagination and server search. Tap opens the shop detail.
///
/// Phase 4 (4.1) — the row is the shared [AdminListCard] shell and
/// the chip is [AdminStatusChip.shopStatus] (the shops tone mapping
/// lives there now, not in a private helper here).
class AdminShopListTile extends StatelessWidget {
  const AdminShopListTile({super.key, required this.shop, required this.onTap});

  final ShopModel shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return AdminListCard(
      icon: Icons.store_rounded,
      title: shop.shopName,
      subtitle:
          // Honesty flag (Worker 1): a number the shop document never
          // stored is hidden, never shown with the display-only
          // fallback — same as shop_list_card.dart.
          '${shop.city} • ${l10n.admin2_shopsPlanLine(shop.plan)}${shop.hasRealRating ? ' • ${l10n.admin2_shopRating(shop.rating.toStringAsFixed(1))}' : ''}',
      trailing: AdminStatusChip.shopStatus(
        suspended: shop.suspended,
        verificationStatus: shop.verificationStatus,
        l10n: l10n,
      ),
      onTap: onTap,
    );
  }
}
