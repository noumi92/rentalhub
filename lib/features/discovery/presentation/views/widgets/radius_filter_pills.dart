import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class RadiusFilterPills extends StatelessWidget {
  final double selectedRadiusKm;
  final ValueChanged<double> onRadiusSelected;

  const RadiusFilterPills({
    super.key,
    required this.selectedRadiusKm,
    required this.onRadiusSelected,
  });

  static const List<double> _radii = [1.0, 2.0, 3.0, 5.0];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Icon(
            Icons.radar_rounded,
            size: 16,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.radiusLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          ..._radii.map((km) {
            final bool isSelected = selectedRadiusKm == km;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onRadiusSelected(km),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    '${km.toInt()} km',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

