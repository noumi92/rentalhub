import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// E2: the shared hero tag for a vehicle's image. [ShopVehicleCard]
/// (shop detail, the source) and [VehicleHeroCard] (vehicle detail, the
/// destination) both use this tag, so tapping a card animates its image
/// into the detail screen. One vehicle id appears at most once per
/// screen, so the tag is unique wherever the cards are used.
String vehicleHeroTag(String vehicleId) => 'vehicle-image-$vehicleId';

class VehicleHeroCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final String carAsset;

  /// A real photo URL when the owner uploaded one (cPanel `vehicles`
  /// folder); when null the asset fallback [carAsset] is shown.
  final String? imageUrl;

  const VehicleHeroCard({
    super.key,
    required this.vehicle,
    required this.carAsset,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: AppCardDecoration.of(context, radius: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // E2: the hero wraps the image widget itself (including
            // its errorBuilder fallback), so the photo animates in
            // from the shop-detail card.
            Hero(tag: vehicleHeroTag(vehicle.vehicleId), child: _buildImage()),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  vehicle.category,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The owner's uploaded photo when there is one, otherwise the asset
  /// illustration for this make/model, with the generic sedan as the last
  /// fallback when even the asset fails to load.
  Widget _buildImage() {
    final url = imageUrl;
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 190,
        errorBuilder: (_, __, ___) => _assetImage(),
      );
    }
    return _assetImage();
  }

  Widget _assetImage() {
    return Image.asset(
      carAsset,
      fit: BoxFit.contain,
      width: double.infinity,
      height: 190,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/white_sedan_hero.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
