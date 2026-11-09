import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../constants/owner_vehicle_constants.dart';
import 'rate_matrix_field_widget.dart';

/// Deck default (024b): Rs 2,000 per night when the vehicle has no
/// stored night-stay rate. Single source of truth — the fare
/// breakdown and the PDF use this same default.
const int kDefaultDriverNightStayPkr = 2000;

/// 010b "Out-of-city rules": the whole Trip charges section,
/// extracted from [OwnerOutCityRulesView] so the view stays under
/// the 250-line cap — deposit, advance, driver night stay
/// (per night, away from the home city) and the fuel-policy and
/// tolls & parking choices. All fields are owned by the view's
/// dirty snapshot; this widget only renders them.
class PricingTripCharges extends StatelessWidget {
  const PricingTripCharges({
    super.key,
    required this.depositController,
    required this.advanceController,
    required this.nightStayController,
    required this.fuelPolicy,
    required this.onFuelPolicyChanged,
    required this.tollsPaidBy,
    required this.onTollsChanged,
  });

  final TextEditingController depositController;
  final TextEditingController advanceController;
  final TextEditingController nightStayController;
  final String fuelPolicy;
  final ValueChanged<String> onFuelPolicyChanged;

  /// 'customer' | 'included' — who pays tolls & parking.
  final String tollsPaidBy;
  final ValueChanged<String> onTollsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.outCityTripCharges,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        RateMatrixFieldWidget(
            controller: depositController,
            label: l10n.pricingSecurityDeposit,
            hint: 'Rs. 25,000',
            kmCap: l10n.pricingSecurityDepositCap),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
            controller: advanceController,
            label: l10n.pricingAdvanceRequired,
            hint: 'Rs. 2,000',
            kmCap: l10n.pricingAdvanceCap),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
            controller: nightStayController,
            label: l10n.outCityNightStay,
            hint: 'Rs. 2,000',
            kmCap: l10n.outCityNightStayCap),
        const SizedBox(height: 14),
        Text(l10n.pricingFuelPolicy,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _dropdown(
          context,
          value: OwnerVehicleConstants.fuelPolicies.contains(fuelPolicy)
              ? fuelPolicy
              : OwnerVehicleConstants.fuelPolicies.first,
          items: OwnerVehicleConstants.fuelPolicies
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (f) {
            if (f != null) onFuelPolicyChanged(f);
          },
        ),
        const SizedBox(height: 14),
        Text(l10n.outCityTolls,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _dropdown(
          context,
          value: tollsPaidBy == 'included' ? 'included' : 'customer',
          items: [
            DropdownMenuItem(
                value: 'customer', child: Text(l10n.outCityTollsCustomer)),
            DropdownMenuItem(
                value: 'included', child: Text(l10n.outCityTollsIncluded)),
          ],
          onChanged: (t) {
            if (t != null) onTollsChanged(t);
          },
        ),
      ],
    );
  }

  Widget _dropdown(
    BuildContext context, {
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: theme.colorScheme.surface,
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
