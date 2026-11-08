import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                      _specChip(context, 
                          Icons.event_seat_rounded, l10n.vehicleSeats(v.seats)),
                      const SizedBox(width: 6),
                      _specChip(context, 
                          Icons.settings_rounded, v.transmission),
                      const SizedBox(width: 6),
                      _specChip(context, Icons.local_gas_station_rounded,
                          v.fuelType),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.vehicleSelfRate(v.rates.daily24),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        l10n.vehicleDriverRate(v.rates.daily24 + (v.withDriverSurchargePkr ?? 0)),
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

  Widget _specChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
