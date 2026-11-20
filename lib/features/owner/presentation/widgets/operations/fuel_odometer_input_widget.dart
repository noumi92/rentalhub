import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/card_decoration.dart';

class FuelOdometerInputWidget extends StatelessWidget {
  final TextEditingController odometerController;
  final String selectedFuel;
  final ValueChanged<String> onFuelSelected;
  final String? title;

  const FuelOdometerInputWidget({
    super.key,
    required this.odometerController,
    required this.selectedFuel,
    required this.onFuelSelected,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    const fuelLevels = ['1/4 (25%)', '2/4 (50%)', '3/4 (75%)', '4/4 (Full)'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? l10n.handoverTelemetryTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(l10n.handoverOdometerLabel,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: odometerController,
            keyboardType: TextInputType.number,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: l10n.handoverOdometerHint,
              suffixText: 'KM',
              suffixStyle: TextStyle(
                  fontWeight: FontWeight.w500, color: AppColors.orangeTextFor(Theme.of(context).brightness)),
              prefixIcon: const Icon(Icons.speed_rounded),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text(l10n.handoverFuelLabel,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          // Item 9 (O28): an E–F slider replaces the four chips — the
          // stored value is unchanged (one of the four level strings),
          // so old records and the return flow keep reading it.
          Row(
            children: [
              Text('E',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
              Expanded(
                child: Slider(
                  value: _fuelSliderValue(selectedFuel),
                  min: 0,
                  max: 3,
                  divisions: 3,
                  label: selectedFuel.isEmpty
                      ? null
                      : fuelLevelLabel(l10n, selectedFuel),
                  onChanged: (v) =>
                      onFuelSelected(fuelLevels[v.round()]),
                ),
              ),
              Text('F',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
            ],
          ),
          if (selectedFuel.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                fuelLevelLabel(l10n, selectedFuel),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  /// Slider position for the stored level; -1 (unselected) reads as
  /// 0 so the thumb rests at E until the owner moves it — the
  /// stored value stays empty until then, so certify still blocks.
  double _fuelSliderValue(String level) {
    const fuelLevels = ['1/4 (25%)', '2/4 (50%)', '3/4 (75%)', '4/4 (Full)'];
    final idx = fuelLevels.indexOf(level);
    return idx < 0 ? 0 : idx.toDouble();
  }
}

/// Stored fuel-level codes mapped to localized labels — the stored
/// value itself is never changed.
String fuelLevelLabel(AppLocalizations l10n, String level) => {'1/4 (25%)': l10n.handoverFuelQuarter, '2/4 (50%)': l10n.handoverFuelHalf, '3/4 (75%)': l10n.handoverFuelThreeQuarter, '4/4 (Full)': l10n.handoverFuelFull}[level] ?? level;
