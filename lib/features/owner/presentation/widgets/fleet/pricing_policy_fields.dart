import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RateMatrixFieldWidget(
          controller: outOfCityController,
          label: 'Out-of-City Daily (24h)',
          hint: 'Rs. 10,500 / day',
          kmCap: '350 km included + tracker cleared',
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: surchargeController,
          label: 'With-Driver Surcharge (per day)',
          hint: 'Rs. 2,000 / day',
          kmCap: 'Added on top of the package price',
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: depositController,
          label: 'Security Deposit',
          hint: 'Rs. 25,000',
          kmCap: 'Refundable after return inspection',
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: advanceController,
          label: 'Advance Required',
          hint: 'Rs. 2,000',
          kmCap: 'Due before the booking is confirmed',
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: extraHourController,
          label: 'Extra Hour Charge',
          hint: 'Rs. 600 / hour',
          kmCap: 'Charged for late returns',
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: extraKmController,
          label: 'Extra KM Charge',
          hint: 'Rs. 100 / km',
          kmCap: 'Charged beyond the included km',
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: outOfCityKmController,
          label: 'Out-of-City KM Allowance (per day)',
          hint: '350 km / day',
          kmCap: 'Tracker clearance required beyond the city',
        ),
        const SizedBox(height: 14),
        Text('Fuel Policy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            )),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
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
