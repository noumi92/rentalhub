import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import 'rate_matrix_field_widget.dart';

/// Audit §5 finish (P4-O07/P4-O09): the "Out-City Rent Rates" list of
/// the rate matrix — the out-of-city daily rate plus the extra-KM
/// charge (with its Per KM toggle) and the out-of-city KM allowance.
/// Moved out of [PricingPolicyFields] so the matrix reads as two
/// separate lists: in-city packages, then these out-city rates.
/// Extracted so [OwnerRateMatrixView] stays under the 250-line cap.
/// 09b §2 modes: each section can be hidden — in Per-km mode the
/// daily rate, the extra-km charge and the km allowance do not apply
/// (the base price IS per km); in Fixed-route mode the flat route
/// price replaces them all. Hidden sections keep their last value
/// and are skipped by validation; the flags default to true so
/// existing callers render exactly as before.
class PricingOutCityRates extends StatelessWidget {
  const PricingOutCityRates({
    super.key,
    required this.outOfCityController,
    required this.extraKmController,
    required this.outOfCityKmController,
    required this.perKmEnabled,
    required this.onPerKmChanged,
    this.showDailyRate = true,
    this.showPerKmToggle = true,
    this.showExtraKm = true,
    this.showKmAllowance = true,
  });

  final TextEditingController outOfCityController;
  final TextEditingController extraKmController;
  final TextEditingController outOfCityKmController;
  final bool perKmEnabled;
  final ValueChanged<bool> onPerKmChanged;
  final bool showDailyRate;
  final bool showPerKmToggle;
  final bool showExtraKm;
  final bool showKmAllowance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDailyRate) ...[
          RateMatrixFieldWidget(
            controller: outOfCityController,
            label: l10n.pricingOutOfCityDaily,
            // Audit 2026-11-15 DS-10: localized hint, no literal 'Rs.'.
            hint: l10n.vehicleDetailDailyRate(l10n.amountRs(formatRs(10500))),
            kmCap: l10n.pricingOutOfCityDailyCap,
          ),
          const SizedBox(height: 10),
        ],
        if (showPerKmToggle) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.pricingPerKmQuestion, style: Theme.of(context).textTheme.bodyMedium),
                    Text(l10n.pricingPerKmQuestionHint, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Switch(value: perKmEnabled, activeThumbColor: AppColors.accentSuccess, onChanged: onPerKmChanged),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (showExtraKm) ...[
          RateMatrixFieldWidget(
            controller: extraKmController,
            label: l10n.pricingExtraKmCharge,
            hint: l10n.farePerKmUnit(l10n.amountRs(formatRs(100))),
            kmCap: l10n.pricingExtraKmCap,
            enabled: perKmEnabled,
          ),
          const SizedBox(height: 10),
        ],
        if (showKmAllowance)
          RateMatrixFieldWidget(
            controller: outOfCityKmController,
            label: l10n.pricingOutOfCityKmAllowance,
            hint: l10n.pricingHintKmPerDay(kDefaultOutCityKmPerDay),
            kmCap: l10n.pricingOutOfCityKmCap,
          ),
      ],
    );
  }
}
