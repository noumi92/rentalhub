import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FuelGaugeWidget extends StatelessWidget {
  /// Value between 0.0 (Empty) and 1.0 (Full), quantized into 8 segments
  final double fuelLevel;
  final ValueChanged<double>? onChanged;
  final String label;

  const FuelGaugeWidget({
    super.key,
    required this.fuelLevel,
    this.onChanged,
    this.label = 'Calibrated 8-Segment Fuel Level',
  });

  @override
  Widget build(BuildContext context) {
    final int activeSegments = (fuelLevel * 8).round().clamp(0, 8);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_gas_station_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeSegments / 8 Bars (${(activeSegments / 8 * 100).round()}%)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(8, (index) {
              final int barNumber = index + 1;
              final bool isFilled = barNumber <= activeSegments;
              Color barColor = AppColors.accentSuccess;
              if (barNumber <= 2) {
                barColor = AppColors.accentDanger;
              } else if (barNumber <= 4) {
                barColor = AppColors.warning;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: onChanged != null
                      ? () => onChanged!(barNumber / 8.0)
                      : null,
                  child: Container(
                    height: 28,
                    margin: EdgeInsets.only(right: index < 7 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? barColor
                          : AppColors.borderSubtle.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isFilled
                            ? barColor.withValues(alpha: 0.8)
                            : AppColors.borderSubtle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'E',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentDanger,
                ),
              ),
              Text(
                '1/4',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '1/2',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '3/4',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'F',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentSuccess,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

