import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';

class VehicleReviewStepWidget extends StatelessWidget {
  final XFile? photoFrontFile;
  final String selectedMake;
  final String selectedModel;
  final String category;
  final int selectedYear;
  final String color;
  final String plateNumber;
  final bool isAutomatic;
  final String fuelType;
  final int seats;
  final int dailyRate;
  final int driverAllowance;
  final bool supportSelfDrive;
  final bool supportWithDriver;
  final int deposit;
  final int advance;
  final int extraHour;
  final String fuelPolicy;

  const VehicleReviewStepWidget({
    super.key,
    required this.photoFrontFile,
    required this.selectedMake,
    required this.selectedModel,
    required this.category,
    required this.selectedYear,
    required this.color,
    required this.plateNumber,
    required this.isAutomatic,
    required this.fuelType,
    required this.seats,
    required this.dailyRate,
    required this.driverAllowance,
    required this.supportSelfDrive,
    required this.supportWithDriver,
    required this.deposit,
    required this.advance,
    required this.extraHour,
    required this.fuelPolicy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.border)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (photoFrontFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(photoFrontFile!.path), width: 56, height: 56, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.directions_car_rounded, color: AppColors.midnightNavy, size: 28),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$selectedMake $selectedModel',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.midnightNavy),
                          ),
                          Text('$category • $selectedYear • $color', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    PakistaniPlateWidget(
                      plateNumber: plateNumber.isEmpty ? 'LEA-23-4567' : plateNumber,
                      isCompact: true,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _reviewSpec('Gear', isAutomatic ? 'Auto' : 'Manual'),
                    _reviewSpec('Fuel', fuelType),
                    _reviewSpec('Seats', '$seats'),
                    _reviewSpec('AC', 'Full AC'),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Self-Drive Rate', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(
                          supportSelfDrive ? 'Rs. $dailyRate/day' : 'Not Offered',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: supportSelfDrive ? AppColors.midnightNavy : AppColors.textMuted),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('With-Driver Rate', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(
                          supportWithDriver ? 'Rs. ${dailyRate + driverAllowance}/day' : 'Not Offered',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: supportWithDriver ? AppColors.sunsetOrange : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _reviewMiniDetail('Deposit', 'Rs. $deposit'),
                    _reviewMiniDetail('Advance', 'Rs. $advance'),
                    _reviewMiniDetail('Overstay', 'Rs. $extraHour/hr'),
                    _reviewMiniDetail('Fuel', fuelPolicy),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.emeraldGreen, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This car will be immediately available in your fleet catalog and visible to nearby customers upon approval.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.midnightNavy, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewSpec(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _reviewMiniDetail(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(val, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
      ],
    );
  }
}

