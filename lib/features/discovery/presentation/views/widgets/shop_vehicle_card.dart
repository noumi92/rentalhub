import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Phase A (A1): one car card on the shop detail screen, extracted so the
/// view stays under the 250-line cap. Shows the owner's uploaded photo
/// when there is one, otherwise the asset illustration for the make/model.
class ShopVehicleCard extends StatelessWidget {
  const ShopVehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
  });

  final VehicleEntity vehicle;
  final VoidCallback? onTap;

  String _assetFor(VehicleEntity v) {
    final nameLower = '${v.make} ${v.model}'.toLowerCase();
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
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetImage(v),
      );
    }
    return _assetImage(v);
  }

  Widget _assetImage(VehicleEntity v) {
    return Image.asset(
      _assetFor(v),
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/white_sedan_hero.png',
        fit: BoxFit.contain,
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'rented':
        return 'Rented Out';
      case 'maintenance':
        return 'In Maintenance';
      default:
        return 'Available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
            // Car Photo Preview
            Container(
              height: 130,
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _carImage(v),
                  // Availability Pill
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successContainerFor(Theme.of(context).brightness),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.successBorderFor(Theme.of(context).brightness)),
                      ),
                      child: Text(
                        _statusLabel(v.status),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          v.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      PakistaniPlateWidget(
                        plateNumber: v.plateNumber,
                        isCompact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _specChip(context, 
                          Icons.event_seat_rounded, '${v.seats} Seats'),
                      _specChip(context, Icons.settings_rounded, v.transmission),
                      _specChip(context, Icons.local_gas_station_rounded, v.fuelType),
                    ],
                  ),
                  const Divider(height: 18),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Self: Rs. ${v.rates.daily24}/day',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'With Driver: Rs. ${v.rates.daily24 + (v.withDriverSurchargePkr ?? 0)}/day',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.secondary),
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

  Widget _specChip(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
