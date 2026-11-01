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

  String _getCarImage(MockVehicle v) {
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
                      final carAsset = _getCarImage(vehicle);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () => onVehicleSelected?.call(vehicle),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Car Photo Preview
                              Container(
                                height: 130,
                                width: double.infinity,
                                color: Colors.white,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      carAsset,
                                      height: 120,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/white_sedan_hero.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    // Availability Pill
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFF86EFAC)),
                                        ),
                                        child: const Text(
                                          'Available',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.emeraldGreen,
                                          ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${vehicle.name} (${vehicle.modelYear})',
                                            style: const TextStyle(
                                              fontSize: 15.5,
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
                                        _specChip(Icons.event_seat_rounded,
                                            '${vehicle.seats} Seats'),
                                        _specChip(Icons.settings_rounded,
                                            vehicle.transmission),
                                        _specChip(
                                            Icons.local_gas_station_rounded,
                                            vehicle.fuelType),
                                      ],
                                    ),
                                    const Divider(height: 18),
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      spacing: 8,
                                      runSpacing: 4,
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
                            ],
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

