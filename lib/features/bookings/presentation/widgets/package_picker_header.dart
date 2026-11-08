import 'package:flutter/material.dart';

import '../../../../core/widgets/minimal_app_bar.dart';
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
    return MinimalAppBar(
      title: l10n.packageSelectTitle,
      subtitle: '$carName • $shopName',
      onBack: onBack,
      actions: [
        PakistaniPlateWidget(plateNumber: plateNumber, isCompact: true)
      ],
    );
  }
}
