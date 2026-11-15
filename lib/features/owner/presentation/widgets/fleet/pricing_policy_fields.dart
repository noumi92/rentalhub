import 'package:flutter/material.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import 'rate_matrix_field_widget.dart';

/// The pricing-policy fields of the rate matrix: with-driver
/// surcharge, security deposit, advance, extra-hour charge and fuel
/// policy. The out-of-city rates live in [PricingOutCityRates] now
/// (audit §5 finish, P4-O07/P4-O09). Extracted from
/// [OwnerRateMatrixView] so the view stays under the 250-line cap.
class PricingPolicyFields extends StatelessWidget {
  const PricingPolicyFields({
    super.key,
    required this.surchargeController,
    required this.depositController,
    required this.advanceController,
    required this.extraHourController,
    required this.fuelPolicy,
    required this.onFuelPolicyChanged,
    required this.fuelPolicies,
  });

  final TextEditingController surchargeController;
  final TextEditingController depositController;
  final TextEditingController advanceController;
  final TextEditingController extraHourController;
  final String fuelPolicy;
  final ValueChanged<String> onFuelPolicyChanged;
  final List<String> fuelPolicies;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RateMatrixFieldWidget(
          controller: surchargeController,
          label: l10n.pricingWithDriverSurcharge,
          // Audit 2026-11-15 DS-10: no hardcoded-English 'Rs.' hint —
          // the money text comes from .arb via amountRs.
          hint: l10n.vehicleDetailDailyRate(l10n.amountRs(formatRs(2000))),
          kmCap: l10n.pricingWithDriverSurchargeCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: depositController,
          label: l10n.pricingSecurityDeposit,
          hint: l10n.amountRs(formatRs(25000)),
          kmCap: l10n.pricingSecurityDepositCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: advanceController,
          label: l10n.pricingAdvanceRequired,
          hint: l10n.amountRs(formatRs(2000)),
          kmCap: l10n.pricingAdvanceCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: extraHourController,
          label: l10n.pricingExtraHourCharge,
          hint: l10n.pricingHintPerHour(l10n.amountRs(formatRs(600))),
          kmCap: l10n.pricingExtraHourCap,
        ),
        const SizedBox(height: 14),
        Text(l10n.pricingFuelPolicy,
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              isExpanded: true,
              value: fuelPolicies.contains(fuelPolicy)
                  ? fuelPolicy
                  : fuelPolicies.first,
              items: fuelPolicies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (f) {
                if (f != null) onFuelPolicyChanged(f);
              },
            ),
          ),
        ),
      ],
    );
  }
}
