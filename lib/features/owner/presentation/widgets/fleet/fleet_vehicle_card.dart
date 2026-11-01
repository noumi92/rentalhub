import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/mock_data.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';

class FleetVehicleCard extends StatelessWidget {
  final MockVehicle vehicle;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onEditRates;

  const FleetVehicleCard({
    super.key,
    required this.vehicle,
    required this.onToggleAvailability,
    required this.onEditRates,
  });

  String _getCarImage(MockVehicle v) {
    if (v.imageUrl.startsWith('/') || v.imageUrl.contains(r'\')) {
      return v.imageUrl;
    }
    final nameLower = v.name.toLowerCase();
    if (nameLower.contains('civic')) {
      return 'assets/images/honda_civic_hero.png';
    } else if (nameLower.contains('corolla') || nameLower.contains('yaris')) {
      return 'assets/images/toyota_corolla.png';
    } else if (nameLower.contains('sportage') || nameLower.contains('br-v')) {
      return 'assets/images/red_civic.png';
    }
    return 'assets/images/white_sedan_hero.png';
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = vehicle.status == 'Available';
    final carAsset = _getCarImage(vehicle);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
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
                  child: carAsset.startsWith('/') || carAsset.contains(r'\')
                      ? Image.file(File(carAsset), width: 72, height: 50, fit: BoxFit.cover)
                      : Image.asset(carAsset, width: 72, height: 50, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.midnightNavy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.transmission} • ${vehicle.fuelType} • ${vehicle.seats} Seats',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                PakistaniPlateWidget(plateNumber: vehicle.plate, isCompact: true),
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
                    const Text('Daily Self-Drive Rate', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                    Text(
                      'Rs. ${vehicle.dailyRate.toInt()}/day',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.midnightNavy),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAvailable ? 'Available' : vehicle.status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isAvailable ? AppColors.emeraldGreen : AppColors.sunsetOrange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isAvailable,
                      activeColor: AppColors.emeraldGreen,
                      onChanged: onToggleAvailability,
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

