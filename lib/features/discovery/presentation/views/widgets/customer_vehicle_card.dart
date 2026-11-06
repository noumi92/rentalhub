import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// B3: one car card on the shop's fleet screen, converted from MockVehicle
/// to the real [VehicleEntity]. Shows the owner's uploaded photo when
/// there is one, otherwise the asset illustration for the make/model.
class CustomerVehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback onTap;

  const CustomerVehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  String _assetFor(VehicleEntity v) {
    final nameLower = v.displayName.toLowerCase();
    if (nameLower.contains('civic')) {
      return 'assets/images/honda_civic_hero.png';
    } else if (nameLower.contains('corolla') || nameLower.contains('yaris')) {
      return 'assets/images/toyota_corolla.png';
    } else if (nameLower.contains('sportage') || nameLower.contains('br-v')) {
      return 'assets/images/red_civic.png';
    }
    return 'assets/images/white_sedan_hero.png';
  }

  Widget _carImage(VehicleEntity v) {
    final url = v.imageUrl;
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          _assetFor(v),
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(_assetFor(v), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: _carImage(v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${v.displayName} (${v.year})',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy,
                          ),
                        ),
                      ),
                      PakistaniPlateWidget(
                        plateNumber: v.plateNumber,
                        isCompact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _specChip(
                          Icons.event_seat_rounded, '${v.seats} Seats'),
                      const SizedBox(width: 6),
                      _specChip(
                          Icons.settings_rounded, v.transmission),
                      const SizedBox(width: 6),
                      _specChip(Icons.local_gas_station_rounded,
                          v.fuelType),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Self: Rs. ${v.rates.daily24}/day',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.midnightNavy,
                        ),
                      ),
                      Text(
                        'With Driver: Rs. ${v.rates.daily24 + (v.withDriverSurchargePkr ?? 0)}/day',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sunsetOrange,
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

  Widget _specChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
