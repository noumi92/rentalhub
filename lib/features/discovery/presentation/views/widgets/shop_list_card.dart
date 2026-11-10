import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/verified_badge.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import 'shops_filter_logic.dart';

class ShopListCard extends StatelessWidget {
  final ShopEntity shop;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const ShopListCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Alternate banner images between showrooms
    final bannerAsset = shop.shopId.hashCode % 2 == 0
        ? 'assets/images/showroom_banner_1.jpg'
        : 'assets/images/showroom_banner_2.jpg';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Showroom Fleet Hero Banner (Screen 07 Reference)
            Stack(
              children: [
                Image.asset(
                  bannerAsset,
                  height: 135,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 135, color: AppColors.primaryContainer,
                    child: const Center(child: Icon(Icons.storefront_rounded, size: 48)),
                  ),
                ),
                // Distance badge — only when the distance is real (never the 1.2 km fallback).
                if (shop.hasRealDistance)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.secondary),
                          const SizedBox(width: 3),
                          Text(
                            '${shop.distanceKm.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // 2. Showroom Metadata & Status
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Verified Badge Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          shop.shopName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Shops tab: every shop states its verification
                      // plainly — "Verified" for verified shops, an
                      // explicit "Unverified" label for the rest
                      // (the badge's own fallback reads "Pending
                      // Review", which is not the same claim).
                      VerifiedBadge(
                        isVerified: isShopVerified(shop),
                        label: isShopVerified(shop)
                            ? null
                            : l10n.shops_unverified,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Rating / cars: a number the shop document never stored is hidden, never shown with the display-only fallback (4.9 / 8 cars).
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Star Rating
                      if (shop.hasRealRating)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text(
                              shop.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      if (shop.hasRealRating)
                        Text('•', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(
                        shop.city.isEmpty ? shop.address : '${shop.address}, ${shop.city}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (shop.hasRealAvailableCount)
                        Text('•', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      if (shop.hasRealAvailableCount)
                        Text(
                          l10n.shopCarsAvailable(shop.availableCount),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Action Bar: Call, WhatsApp, View Fleet
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      // Direct Phone Call Button
                      OutlinedButton.icon(
                        onPressed: onCall ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      l10n.callingShopNumber(shop.shopName, shop.phoneNumber)),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.call_rounded,
                            size: 14),
                        label: Text(l10n.call),
                      ),

                      // Direct WhatsApp Chat Button
                      OutlinedButton.icon(
                        onPressed: onWhatsApp ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      l10n.openingWhatsappShop(shop.shopName)),
                                  backgroundColor: AppColors.successContainerFor(Theme.of(context).brightness),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.successOnContainerFor(Theme.of(context).brightness),
                          side: BorderSide(color: AppColors.successBorderFor(Theme.of(context).brightness)),
                          backgroundColor: AppColors.successContainerFor(Theme.of(context).brightness),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(Icons.chat_bubble_outline_rounded,
                            size: 14, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
                        label: Text(l10n.whatsapp),
                      ),

                      // View Showroom Fleet CTA
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.viewFleet),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
