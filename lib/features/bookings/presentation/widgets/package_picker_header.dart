import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';

/// The header of the booking picker: back button, title and the
/// car's plate. Extracted from [RentPackagePickerView] so the view
/// stays under the 250-line cap.
class PackagePickerHeader extends StatelessWidget {
  const PackagePickerHeader({
    super.key,
    required this.carName,
    required this.shopName,
    required this.plateNumber,
    required this.onBack,
  });

  final String carName;
  final String shopName;
  final String plateNumber;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return CustomCurvedHeader(
      height: 100,
      leadingWidget: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: onBack,
            )
          : null,
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Rental Package',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          Text('$carName • $shopName',
              style: const TextStyle(
                  color: AppColors.textLavender, fontSize: 12)),
        ],
      ),
      actions: [
        PakistaniPlateWidget(plateNumber: plateNumber, isCompact: true)
      ],
    );
  }
}
