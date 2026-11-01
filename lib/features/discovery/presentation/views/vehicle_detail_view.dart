import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';

class VehicleDetailView extends StatefulWidget {
  final MockVehicle vehicle;
  final VoidCallback? onBookNow;
  final VoidCallback? onBack;

  const VehicleDetailView({
    super.key,
    required this.vehicle,
    this.onBookNow,
    this.onBack,
  });

  @override
  State<VehicleDetailView> createState() => _VehicleDetailViewState();
}

class _VehicleDetailViewState extends State<VehicleDetailView> {
  bool _withDriver = true;

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final int selectedRate =
        _withDriver ? v.withDriverDailyRate : v.selfDriveDailyRate;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCurvedHeader(
              height: 175,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.name} (${v.modelYear})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${v.shopName} • ${v.category}',
                    style: const TextStyle(
                      color: AppColors.textLavender,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                PakistaniPlateWidget(
                  plateNumber: v.plateNumber,
                  isCompact: true,
                ),
              ],
            ),
            HeaderOverlapContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Rental Mode (Dual-Mode Rate Matrix)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _modeTile(
                                title: 'With Driver',
                                urdu: 'ڈرائیور کے ساتھ',
                                rate: v.withDriverDailyRate,
                                isSelected: _withDriver,
                                onTap: () =>
                                    setState(() => _withDriver = true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _modeTile(
                                title: 'Self-Drive',
                                urdu: 'سیلف ڈرائیو',
                                rate: v.selfDriveDailyRate,
                                isSelected: !_withDriver,
                                onTap: () =>
                                    setState(() => _withDriver = false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _withDriver
                                ? AppColors.emeraldGreen.withValues(alpha: 0.08)
                                : AppColors.amberGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _withDriver
                                ? 'Chauffeur Included • Overtime: Rs. ${v.overtimeHourlyRate}/hr • Out-of-City: +Rs. ${v.outstationAllowance}/day'
                                : 'Security Deposit: Rs. ${v.securityDeposit} + Original NADRA CNIC Guarantee',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.midnightNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DebouncedButton(
                          text: 'Proceed to Book (Rs. $selectedRate/day)',
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: () async {
                            widget.onBookNow?.call();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTile({
    required String title,
    required String urdu,
    required int rate,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sunsetOrange.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.sunsetOrange : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.midnightNavy,
              ),
            ),
            Text(
              urdu,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.sunsetOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Rs. $rate/day',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.midnightNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

