import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'rate_matrix_field_widget.dart';

/// The pricing-policy fields of the rate matrix: out-of-city daily rate,
/// with-driver surcharge, security deposit, advance, extra-hour charge
/// and fuel policy. Extracted from [OwnerRateMatrixView] so the view
/// stays under the 250-line cap.
class PricingPolicyFields extends StatelessWidget {
  const PricingPolicyFields({
    super.key,
    required this.outOfCityController,
    required this.surchargeController,
    required this.depositController,
    required this.advanceController,
    required this.extraHourController,
    required this.extraKmController,
    required this.outOfCityKmController,
    required this.fuelPolicy,
    required this.onFuelPolicyChanged,
    required this.fuelPolicies,
  });

  final TextEditingController outOfCityController;
  final TextEditingController surchargeController;
  final TextEditingController depositController;
  final TextEditingController advanceController;
  final TextEditingController extraHourController;
  final TextEditingController extraKmController;
  final TextEditingController outOfCityKmController;
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
          controller: outOfCityController,
          label: l10n.pricingOutOfCityDaily,
          hint: 'Rs. 10,500 / day',
          kmCap: l10n.pricingOutOfCityDailyCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: surchargeController,
          label: l10n.pricingWithDriverSurcharge,
          hint: 'Rs. 2,000 / day',
          kmCap: l10n.pricingWithDriverSurchargeCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: depositController,
          label: l10n.pricingSecurityDeposit,
          hint: 'Rs. 25,000',
          kmCap: l10n.pricingSecurityDepositCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: advanceController,
          label: l10n.pricingAdvanceRequired,
          hint: 'Rs. 2,000',
          kmCap: l10n.pricingAdvanceCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: extraHourController,
          label: l10n.pricingExtraHourCharge,
          hint: 'Rs. 600 / hour',
          kmCap: l10n.pricingExtraHourCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: extraKmController,
          label: l10n.pricingExtraKmCharge,
          hint: 'Rs. 100 / km',
          kmCap: l10n.pricingExtraKmCap,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: outOfCityKmController,
          label: l10n.pricingOutOfCityKmAllowance,
          hint: '350 km / day',
          kmCap: l10n.pricingOutOfCityKmCap,
        ),
        const SizedBox(height: 14),
        Text(l10n.pricingFuelPolicy,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )),
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
