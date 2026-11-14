import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import 'vehicle_package_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/money_format.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    final selfDriveRate = v.rates.daily24;
    final withDriverRate =
        v.rates.daily24 + (v.withDriverSurchargePkr ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.vehicleChoosePackage,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        // Equal-height package cards: without IntrinsicHeight the
        // two cards differ in height when one label wraps at 360px /
        // large text scale.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: VehiclePackageCard(
                  title: l10n.selfDrive,
                  urdu: l10n.vehicleSelfDriveUrdu,
                  price: selfDriveRate,
                  isSelected: !withDriver,
                  icon: Icons.drive_eta_rounded,
                  onTap: () => onDriveModeChanged(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VehiclePackageCard(
                  title: l10n.withDriver,
                  urdu: l10n.vehicleWithDriverUrdu,
                  price: withDriverRate,
                  isSelected: withDriver,
                  icon: Icons.person_pin_rounded,
                  onTap: () => onDriveModeChanged(true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Brightness-aware slab colours: the old raw-alpha
            // warning fill with a primary-navy icon was unreadable
            // in dark mode (navy on dark amber), and the success
            // icon at #10B981 on the pale slab was below AA.
            color: withDriver
                ? AppColors.successContainerFor(Theme.of(context).brightness)
                : AppColors.warningContainerFor(Theme.of(context).brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: withDriver
                    ? AppColors.successBorderFor(Theme.of(context).brightness).withValues(alpha: 0.5)
                    : AppColors.warningOnContainerFor(Theme.of(context).brightness).withValues(alpha: 0.35)),
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
                      ? AppColors.successOnContainerFor(Theme.of(context).brightness)
                      : AppColors.warningOnContainerFor(Theme.of(context).brightness)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  withDriver
                      ? l10n.vehicleDriverPackageDetail(formatRs(v.extraHourPkr ?? 0), formatRs(v.rates.outOfCityDaily ?? 0))
                      : l10n.vehicleDepositCnic(formatRs(v.securityDepositPkr ?? 0)),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
