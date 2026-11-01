import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/shop_entity.dart';

class ShopMapView extends StatelessWidget {
  final List<ShopEntity> shops;
  final double radiusKm;
  final ValueChanged<ShopEntity> onShopSelected;

  const ShopMapView({
    super.key,
    required this.shops,
    required this.radiusKm,
    required this.onShopSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar circle
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sunsetOrange.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.sunsetOrange.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
          ),
          const Icon(
            Icons.my_location_rounded,
            color: AppColors.midnightNavy,
            size: 28,
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.midnightNavy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'GPS Radar: ${radiusKm.toInt()} km (${shops.length} Verified Shops)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ...shops.asMap().entries.map((entry) {
            final idx = entry.key;
            final shop = entry.value;
            final offsets = [
              const Alignment(-0.45, -0.35),
              const Alignment(0.5, -0.25),
              const Alignment(-0.35, 0.45),
              const Alignment(0.45, 0.4),
            ];
            return Align(
              alignment: offsets[idx % offsets.length],
              child: InkWell(
                onTap: () => onShopSelected(shop),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sunsetOrange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${shop.distanceKm}km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

