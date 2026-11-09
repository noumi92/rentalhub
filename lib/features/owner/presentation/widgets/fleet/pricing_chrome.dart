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
    this.title,
  });

  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  /// 09b: the package-rates editor shows "Package rates" instead of
  /// the old "Vehicle Pricing Matrix" title. Null keeps the old title.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MinimalAppBar(
      title: title ?? l10n.pricingTitle,
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
    this.onViewEstimate,
    this.label,
  });

  final bool isSaving;
  final VoidCallback onPressed;

  /// Audit §5 (P4-O08): optional link to the estimated-rates card.
  final VoidCallback? onViewEstimate;

  /// 09b/010b: the save button label ("Save package" / "Save rules").
  /// Null keeps the old "Save Pricing Matrix" label.
  final String? label;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onViewEstimate != null)
            TextButton.icon(
              onPressed: onViewEstimate,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: Text(l10n.ratesViewEstimate),
            ),
          DebouncedButton(
            text: isSaving ? l10n.pricingSaving : (label ?? l10n.pricingSave),
            icon: Icons.check_circle_rounded,
            isLoading: isSaving,
            onPressed: () async => onPressed(),
          ),
        ],
      ),
    );
  }
}
