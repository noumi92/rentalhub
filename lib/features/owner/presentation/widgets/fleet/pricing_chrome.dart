import 'package:flutter/material.dart';

import '../../../../../core/widgets/minimal_app_bar.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Header and save bar of the rate matrix, extracted from
/// [OwnerRateMatrixView] so the view stays under the 250-line cap.
class PricingHeader extends StatelessWidget {
  const PricingHeader({
    super.key,
    required this.vehicle,
    required this.onBack,
  });

  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MinimalAppBar(
      title: l10n.pricingTitle,
      subtitle: '${vehicle.make} ${vehicle.model} (${vehicle.year})',
      onBack: onBack,
      actions: [
        PakistaniPlateWidget(plateNumber: vehicle.plateNumber, isCompact: true)
      ],
    );
  }
}

class PricingSaveBar extends StatelessWidget {
  const PricingSaveBar({
    super.key,
    required this.isSaving,
    required this.onPressed,
  });

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: DebouncedButton(
        text: isSaving ? l10n.pricingSaving : l10n.pricingSave,
        icon: Icons.check_circle_rounded,
        isLoading: isSaving,
        onPressed: () async => onPressed(),
      ),
    );
  }
}
