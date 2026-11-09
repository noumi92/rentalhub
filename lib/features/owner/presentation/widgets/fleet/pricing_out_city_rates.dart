import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import 'rate_matrix_field_widget.dart';

/// Audit §5 finish (P4-O07/P4-O09): the "Out-City Rent Rates" list of
/// the rate matrix — the out-of-city daily rate plus the extra-KM
/// charge (with its Per KM toggle) and the out-of-city KM allowance.
/// Moved out of [PricingPolicyFields] so the matrix reads as two
/// separate lists: in-city packages, then these out-city rates.
/// Extracted so [OwnerRateMatrixView] stays under the 250-line cap.
class PricingOutCityRates extends StatelessWidget {
  const PricingOutCityRates({
    super.key,
    required this.outOfCityController,
    required this.extraKmController,
    required this.outOfCityKmController,
    required this.perKmEnabled,
    required this.onPerKmChanged,
  });

  final TextEditingController outOfCityController;
  final TextEditingController extraKmController;
  final TextEditingController outOfCityKmController;
  final bool perKmEnabled;
  final ValueChanged<bool> onPerKmChanged;

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
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.pricingPerKmQuestion, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(l10n.pricingPerKmQuestionHint, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            Switch(value: perKmEnabled, activeThumbColor: AppColors.accentSuccess, onChanged: onPerKmChanged),
          ],
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: extraKmController,
          label: l10n.pricingExtraKmCharge,
          hint: 'Rs. 100 / km',
          kmCap: l10n.pricingExtraKmCap,
          enabled: perKmEnabled,
        ),
        const SizedBox(height: 10),
        RateMatrixFieldWidget(
          controller: outOfCityKmController,
          label: l10n.pricingOutOfCityKmAllowance,
          hint: '350 km / day',
          kmCap: l10n.pricingOutOfCityKmCap,
        ),
      ],
    );
  }
}
