import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import 'vehicle_package_card.dart';

/// Phase A (A1): the drive-mode + package section of the car detail
/// screen, extracted so the view stays under the 250-line cap.
class VehicleDetailPackages extends StatelessWidget {
  const VehicleDetailPackages({
    super.key,
    required this.vehicle,
    required this.withDriver,
    required this.onDriveModeChanged,
  });

  final VehicleEntity vehicle;
  final bool withDriver;
  final ValueChanged<bool> onDriveModeChanged;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final selfDriveRate = v.rates.daily24;
    final withDriverRate =
        v.rates.daily24 + (v.withDriverSurchargePkr ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Rental Package',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: VehiclePackageCard(
                title: 'Self Drive',
                urdu: 'سیلف ڈرائیو',
                price: selfDriveRate,
                isSelected: !withDriver,
                icon: Icons.drive_eta_rounded,
                onTap: () => onDriveModeChanged(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VehiclePackageCard(
                title: 'With Driver',
                urdu: 'ڈرائیور کے ساتھ',
                price: withDriverRate,
                isSelected: withDriver,
                icon: Icons.person_pin_rounded,
                onTap: () => onDriveModeChanged(true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: withDriver
                ? AppColors.accentSuccess.withValues(alpha: 0.08)
                : AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: withDriver
                    ? AppColors.accentSuccess.withValues(alpha: 0.25)
                    : AppColors.warning.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                  withDriver
                      ? Icons.verified_user_rounded
                      : Icons.security_rounded,
                  size: 18,
                  color: withDriver
                      ? AppColors.accentSuccess
                      : AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  withDriver
                      ? 'Verified chauffeur included • Overtime: Rs. ${v.extraHourPkr ?? 0}/hr • Outstation: +Rs. ${v.rates.outOfCityDaily ?? 0}/day'
                      : 'Security Deposit: Rs. ${v.securityDepositPkr ?? 0} + Original NADRA CNIC guarantee required at pickup',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
