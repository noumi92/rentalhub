import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/verified_badge.dart';
import '../../../domain/entities/shop_entity.dart';

class MapShopPreviewCard extends StatelessWidget {
  final ShopEntity shop;
  final VoidCallback onViewShowroom;

  const MapShopPreviewCard({
    super.key,
    required this.shop,
    required this.onViewShowroom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.midnightNavy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.shopName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${shop.address} • ${shop.distanceKm} km away',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  VerifiedBadge(isVerified: shop.isVerified),
                  const SizedBox(width: 8),
                  Text(
                    '★ ${shop.rating} Rating',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${shop.availableCount} Cars Ready',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${shop.shopName}...'),
                          backgroundColor: AppColors.midnightNavy,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.midnightNavy,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 14, color: AppColors.primary),
                    label: const Text('Call', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening WhatsApp with ${shop.shopName}...'),
                          backgroundColor: AppColors.emeraldGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emeraldGreen,
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      backgroundColor: const Color(0xFFF0FDF4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.emeraldGreen),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  ElevatedButton.icon(
                    onPressed: onViewShowroom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sunsetOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.directions_car_rounded, size: 14),
                    label: const Text('View Fleet', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
