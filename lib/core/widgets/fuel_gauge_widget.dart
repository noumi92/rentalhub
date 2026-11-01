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
        border: Border.all(color: AppColors.border),
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
                    color: AppColors.sunsetOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.midnightNavy,
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnightNavy,
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
              Color barColor = AppColors.emeraldGreen;
              if (barNumber <= 2) {
                barColor = AppColors.crimsonRed;
              } else if (barNumber <= 4) {
                barColor = AppColors.amberGold;
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
                          : AppColors.border.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isFilled
                            ? barColor.withValues(alpha: 0.8)
                            : AppColors.border,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'E',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.crimsonRed,
                ),
              ),
              Text(
                '1/4',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '1/2',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.midnightNavy,
                ),
              ),
              Text(
                '3/4',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                'F',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.emeraldGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

