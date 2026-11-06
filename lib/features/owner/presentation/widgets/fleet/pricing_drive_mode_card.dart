import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// The drive-mode availability card of the rate matrix.
/// Extracted from [OwnerRateMatrixView] so the view stays under the
/// 250-line cap. Phase B (B2) note: these switches used to be loaded
/// but never saved — the view now persists them with the matrix.
class PricingDriveModeCard extends StatelessWidget {
  const PricingDriveModeCard({
    super.key,
    required this.isSelfDrive,
    required this.onSelfDriveChanged,
    required this.isWithDriver,
    required this.onWithDriverChanged,
  });

  final bool isSelfDrive;
  final ValueChanged<bool> onSelfDriveChanged;
  final bool isWithDriver;
  final ValueChanged<bool> onWithDriverChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            SwitchListTile(
              activeThumbColor: AppColors.sunsetOrange,
              title: const Text('Self-Drive Allowed',
                  style:
                      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              subtitle: const Text(
                  'Requires original NADRA CNIC + security deposit',
                  style: TextStyle(fontSize: 11)),
              value: isSelfDrive,
              onChanged: onSelfDriveChanged,
            ),
            const Divider(height: 1),
            SwitchListTile(
              activeThumbColor: AppColors.sunsetOrange,
              title: const Text('Chauffeur Service Allowed',
                  style:
                      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              subtitle:
                  const Text('Showroom driver assigned to booking',
                      style: TextStyle(fontSize: 11)),
              value: isWithDriver,
              onChanged: onWithDriverChanged,
            ),
          ],
        ),
      ),
    );
  }
}
