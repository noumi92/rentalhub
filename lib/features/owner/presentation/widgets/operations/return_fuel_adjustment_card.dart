import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../finance/utils/settlement_calculator.dart';

/// Compares return fuel level against the recorded handover fuel level and,
/// when return fuel is lower, prompts the owner to enter or confirm fuel charges.
class ReturnFuelAdjustmentCard extends StatelessWidget {
  const ReturnFuelAdjustmentCard({
    super.key,
    required this.handoverFuelLevel,
    required this.returnFuelLevel,
    required this.controller,
    required this.onChanged,
  });

  final String? handoverFuelLevel;
  final String returnFuelLevel;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final handover = handoverFuelLevel;
    final hasHandover = handover != null && handover.isNotEmpty;
    final suggestedDeficit = SettlementCalculator.fuelDeficitFor(
      returnFuelLevel,
      handoverFuelLevel: handover,
    );
    if (!hasHandover && suggestedDeficit <= 0) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final isLower = suggestedDeficit > 0;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLower
              ? AppColors.warningContainerFor(brightness)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLower
                ? AppColors.warningTextFor(brightness).withValues(alpha: 0.35)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHandover)
              Row(
                children: [
                  Icon(
                    Icons.local_gas_station_rounded,
                    size: 18,
                    color: isLower
                        ? AppColors.warningTextFor(brightness)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.returnHandoverFuelCompare(handover, returnFuelLevel),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            if (isLower) ...[
              if (hasHandover) const SizedBox(height: 6),
              Text(
                l10n.returnFuelLowerHint(handover ?? '4/4 (Full)'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warningTextFor(brightness),
                    ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('return_fuel_charge_field'),
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
                decoration: InputDecoration(
                  labelText: l10n.returnFuelChargesLabel,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
