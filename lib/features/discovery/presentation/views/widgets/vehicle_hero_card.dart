import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildImage(),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.midnightNavy.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  vehicle.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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

