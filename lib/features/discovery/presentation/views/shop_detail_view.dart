import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../domain/entities/shop_entity.dart';

class ShopDetailView extends StatelessWidget {
  final ShopEntity shop;
  final ValueChanged<MockVehicle>? onVehicleSelected;
  final VoidCallback? onBack;

  const ShopDetailView({
    super.key,
    required this.shop,
    this.onVehicleSelected,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final vehicles = MockDatabase.vehicles
        .where((v) => v.shopName == shop.shopName || v.shopId == shop.shopId)
        .toList();
    final displayVehicles =
        vehicles.isNotEmpty ? vehicles : MockDatabase.vehicles;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCurvedHeader(
              height: 170,
              leadingWidget: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.shopName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${shop.address}, ${shop.city} (${shop.distanceKm} km)',
                    style: const TextStyle(
                      color: AppColors.textLavender,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              bottomWidget: VerifiedBadge(isVerified: shop.isVerified),
            ),
            HeaderOverlapContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...displayVehicles.map((vehicle) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => onVehicleSelected?.call(vehicle),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${vehicle.name} (${vehicle.modelYear})',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.midnightNavy,
                                        ),
                                      ),
                                    ),
                                    PakistaniPlateWidget(
                                      plateNumber: vehicle.plateNumber,
                                      isCompact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    _specChip(
                                        Icons.event_seat_rounded,
                                        '${vehicle.seats} Seats'),
                                    _specChip(Icons.settings_rounded,
                                        vehicle.transmission),
                                    _specChip(Icons.local_gas_station_rounded,
                                        vehicle.fuelType),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Self: Rs. ${vehicle.selfDriveDailyRate}/day',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.midnightNavy,
                                      ),
                                    ),
                                    Text(
                                      'With Driver: Rs. ${vehicle.withDriverDailyRate}/day',
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
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

