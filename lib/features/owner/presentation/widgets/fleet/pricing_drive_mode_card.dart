import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          
        ),
        child: Column(
          children: [
            SwitchListTile(
              activeThumbColor: Theme.of(context).colorScheme.secondary,
              title: Text(l10n.pricingSelfDriveAllowed,
                  style:
                      Theme.of(context).textTheme.bodyMedium),
              subtitle: Text(
                  l10n.pricingSelfDriveHint,
                  style: Theme.of(context).textTheme.labelSmall),
              value: isSelfDrive,
              onChanged: onSelfDriveChanged,
            ),
            const Divider(height: 1),
            SwitchListTile(
              activeThumbColor: Theme.of(context).colorScheme.secondary,
              title: Text(l10n.pricingChauffeurAllowed,
                  style:
                      Theme.of(context).textTheme.bodyMedium),
              subtitle:
                  Text(l10n.pricingChauffeurHint,
                      style: Theme.of(context).textTheme.labelSmall),
              value: isWithDriver,
              onChanged: onWithDriverChanged,
            ),
          ],
        ),
      ),
    );
  }
}
