import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Phase B (B1): fleet card for a real [VehicleEntity] (was MockVehicle).
/// The photo is the vehicle's uploaded image when one exists (network URL
/// from cPanel, or a local file path on the owner's phone); otherwise the
/// old name-based asset fallback is kept so cars without photos still
/// show a sensible image.
class FleetVehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onEditRates;
  final VoidCallback onViewCalendar;

  const FleetVehicleCard({
    super.key,
    required this.vehicle,
    required this.onToggleAvailability,
    required this.onEditRates,
    required this.onViewCalendar,
  });

  Widget _carImage(VehicleEntity v) {
    final imageUrl = v.imageUrl;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 72,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetImage(_assetFor(v)),
      );
    }
    if (imageUrl != null &&
        (imageUrl.startsWith('/') || imageUrl.contains(r'\'))) {
      return Image.file(
        File(imageUrl),
        width: 72,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetImage(_assetFor(v)),
      );
    }
    return _assetImage(_assetFor(v));
  }

  Widget _assetImage(String asset) =>
      Image.asset(asset, width: 72, height: 50, fit: BoxFit.cover);

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

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'rented':
        return 'On Rent';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = vehicle.status == 'available';

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _carImage(vehicle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.transmission} • ${vehicle.fuelType} • ${vehicle.seats} Seats',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                PakistaniPlateWidget(
                    plateNumber: vehicle.plateNumber, isCompact: true),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Self-Drive Rate',
                        style: Theme.of(context).textTheme.labelSmall),
                    Text(
                      'Rs. ${vehicle.rates.daily24}/day',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusLabel(vehicle.status),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isAvailable
                            ? AppColors.accentSuccess
                            : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isAvailable,
                      activeThumbColor: AppColors.accentSuccess,
                      onChanged: onToggleAvailability,
                    ),
                    IconButton(
                      tooltip: 'Edit rates',
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      color: AppColors.primary,
                      onPressed: onEditRates,
                    ),
                    IconButton(
                      tooltip: 'Booking calendar',
                      icon: const Icon(Icons.calendar_month_rounded, size: 20),
                      color: AppColors.primary,
                      onPressed: onViewCalendar,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
