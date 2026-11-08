import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return CustomCurvedHeader(
      variant: CustomCurvedHeaderVariant.compact,
      leadingWidget: onBack != null
          ? IconButton(
              tooltip: l10n.back,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: onBack,
            )
          : null,
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.packageSelectTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
          Text('$carName • $shopName',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primaryContainer)),
        ],
      ),
      actions: [
        PakistaniPlateWidget(plateNumber: plateNumber, isCompact: true)
      ],
    );
  }
}
