import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../discovery/domain/entities/shop_entity.dart';

class CustomerSavedShopsView extends StatelessWidget {
  final List<ShopEntity>? savedShops;
  final ValueChanged<ShopEntity>? onSelectShop;
  final VoidCallback? onBack;

  const CustomerSavedShopsView({
    super.key,
    this.savedShops,
    this.onSelectShop,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final list = savedShops ??
        const [
          ShopEntity(
            shopId: 'shop-01',
            ownerId: 'owner-01',
            shopName: 'Al-Falah Rent a Car',
            phoneNumber: '+923001234567',
            address: 'Main Boulevard, Gulberg III',
            city: 'Lahore',
            geoLocation: GeoPointEntity(31.5204, 74.3587),
            rating: 4.9,
            availableCount: 14,
            isVerified: true,
          ),
          ShopEntity(
            shopId: 'shop-02',
            ownerId: 'owner-02',
            shopName: 'Capital Wheels Islamabad',
            phoneNumber: '+923019876543',
            address: 'Blue Area, Sector F-6',
            city: 'Islamabad',
            geoLocation: GeoPointEntity(33.7294, 73.0931),
            rating: 4.8,
            availableCount: 8,
            isVerified: true,
          ),
        ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: const Text(
                'Saved Showrooms',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.favorite_border_rounded,
                              size: 46, color: AppColors.textSecondary),
                          SizedBox(height: 8),
                          Text('No saved showrooms yet.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final shop = list[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: InkWell(
                            onTap: () => onSelectShop?.call(shop),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.lavenderMist,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.storefront_rounded,
                                        color: AppColors.royalNavy),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(shop.shopName,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.midnightNavy)),
                                        const SizedBox(height: 2),
                                        Text('${shop.address}, ${shop.city}',
                                            style: const TextStyle(
                                                fontSize: 11.5,
                                                color:
                                                    AppColors.textSecondary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 14,
                                                color: AppColors.amberGold),
                                            const SizedBox(width: 3),
                                            Text('${shop.rating}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            const SizedBox(width: 8),
                                            Text(
                                                '• ${shop.availableCount} Cars Ready',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors
                                                        .emeraldGreen,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
