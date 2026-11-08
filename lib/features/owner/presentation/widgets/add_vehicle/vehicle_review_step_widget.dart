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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).dividerColor)),
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
                        child: const Icon(Icons.directions_car_rounded, size: 28),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$selectedMake $selectedModel',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text('$category • $selectedYear • $color', style: Theme.of(context).textTheme.bodySmall),
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
                    _reviewSpec(context, 'Gear', isAutomatic ? 'Auto' : 'Manual'),
                    _reviewSpec(context, 'Fuel', fuelType),
                    _reviewSpec(context, 'Seats', '$seats'),
                    _reviewSpec(context, 'AC', 'Full AC'),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Self-Drive Rate', style: Theme.of(context).textTheme.labelSmall),
                        Text(
                          supportSelfDrive ? 'Rs. $dailyRate/day' : 'Not Offered',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: supportSelfDrive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('With-Driver Rate', style: Theme.of(context).textTheme.labelSmall),
                        Text(
                          supportWithDriver ? 'Rs. ${dailyRate + driverAllowance}/day' : 'Not Offered',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: supportWithDriver ? AppColors.secondary : Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _reviewMiniDetail(context, 'Deposit', 'Rs. $deposit'),
                    _reviewMiniDetail(context, 'Advance', 'Rs. $advance'),
                    _reviewMiniDetail(context, 'Overstay', 'Rs. $extraHour/hr'),
                    _reviewMiniDetail(context, 'Fuel', fuelPolicy),
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
            color: AppColors.successContainerFor(Theme.of(context).brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.successBorderFor(Theme.of(context).brightness)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.successOnContainerFor(Theme.of(context).brightness), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This car will be immediately available in your fleet catalog and visible to nearby customers upon approval.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewSpec(BuildContext context, String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        Text(title, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _reviewMiniDetail(BuildContext context, String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(val, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

