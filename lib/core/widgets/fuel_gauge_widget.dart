import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/card_decoration.dart';

class FuelGaugeWidget extends StatelessWidget {
  /// Value between 0.0 (Empty) and 1.0 (Full), quantized into 8 segments
  final double fuelLevel;
  final ValueChanged<double>? onChanged;
  final String? label;

  const FuelGaugeWidget({
    super.key,
    required this.fuelLevel,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final int activeSegments = (fuelLevel * 8).round().clamp(0, 8);
    // Phase F: the label and the per-bar semantics label are
    // localized; an explicit [label] still wins. English fallback
    // for delegate-less pumps.
    final l10n = AppLocalizations.of(context);
    final gaugeLabel =
        label ?? l10n?.fuelGaugeLabel ?? 'Calibrated 8-Segment Fuel Level';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Card rework (2026-11-10): theme surface, not a hardcoded
        // white — the gauge text uses theme styles, so a hardcoded
        // white fill was unreadable in dark mode.
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // E3: the label flexes and ellipsizes instead of pushing
              // the value pill off-screen — at large text scales the
              // 'Calibrated 8-Segment Fuel Level' label overflowed by
              // 305px in the test font.
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_gas_station_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        gaugeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n?.fuelGaugeBars(
                          activeSegments, (activeSegments / 8 * 100).round()) ??
                      '$activeSegments / 8 Bars (${(activeSegments / 8 * 100).round()}%)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
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
                // E3: each bar is a labelled button (fuel level N of 8),
                // and the tap target is 48dp tall — the 28dp coloured bar
                // itself is centred inside the hit area, so the visual
                // gauge is unchanged.
                child: Semantics(
                  button: true,
                  enabled: onChanged != null,
                  label: l10n?.fuelGaugeSetLevel(barNumber) ??
                      'Set fuel level to $barNumber of 8',
                  child: GestureDetector(
                    onTap: onChanged != null
                        ? () => onChanged!(barNumber / 8.0)
                        : null,
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: Container(
                          height: 28,
                          margin: EdgeInsets.only(right: index < 7 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: isFilled
                                ? barColor
                                : Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isFilled
                                  ? barColor.withValues(alpha: 0.8)
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
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
                      fontWeight: FontWeight.w500,
                      color:
                          AppColors.dangerTextFor(Theme.of(context).brightness),
                    ),
              ),
              Text(
                '1/4',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '1/2',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '3/4',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                'F',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.successTextFor(
                          Theme.of(context).brightness),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
