import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/verified_badge.dart';
import '../../../domain/entities/shop_entity.dart';

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
        side: const BorderSide(color: AppColors.border),
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
                    height: 135,
                    color: AppColors.primaryContainer,
                    child: const Center(
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 48,
                        color: AppColors.midnightNavy,
                      ),
                    ),
                  ),
                ),
                // Distance badge on top-right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.sunsetOrange,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${shop.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnightNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      VerifiedBadge(isVerified: shop.isVerified),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Rating, Location, and Available Cars Info
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Star Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.amberGold,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            shop.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.midnightNavy,
                            ),
                          ),
                        ],
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      Text(
                        '${shop.address}, ${shop.city}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      Text(
                        '${shop.availableCount} cars available',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldGreen,
                        ),
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
                                      'Calling ${shop.shopName} (${shop.phoneNumber})...'),
                                  backgroundColor: AppColors.midnightNavy,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.midnightNavy,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.call_rounded,
                            size: 14, color: AppColors.primary),
                        label: const Text('Call',
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),

                      // Direct WhatsApp Chat Button
                      OutlinedButton.icon(
                        onPressed: onWhatsApp ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Opening WhatsApp with ${shop.shopName}...'),
                                  backgroundColor: AppColors.emeraldGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emeraldGreen,
                          side: const BorderSide(color: Color(0xFF86EFAC)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 14, color: AppColors.emeraldGreen),
                        label: const Text('WhatsApp',
                            style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),

                      // View Showroom Fleet CTA
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sunsetOrange,
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View Fleet',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800)),
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
