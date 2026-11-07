import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/custom_curved_header.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
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
          Text('Vehicle Pricing Matrix',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              )),
          Text('${vehicle.make} ${vehicle.model} (${vehicle.year})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryContainer,
              )),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -3))
        ],
      ),
      child: DebouncedButton(
        text: isSaving ? 'Saving Matrix...' : 'Save Pricing Matrix',
        icon: Icons.check_circle_rounded,
        isLoading: isSaving,
        onPressed: () async => onPressed(),
      ),
    );
  }
}
