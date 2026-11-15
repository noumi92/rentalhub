import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';

class VehicleRatesStepWidget extends StatelessWidget {
  final bool enable1Hour;
  final ValueChanged<bool> onToggle1Hour;
  final TextEditingController rate1HourController;

  final bool enable3Hours;
  final ValueChanged<bool> onToggle3Hours;
  final TextEditingController rate3HoursController;

  final bool enable6Hours;
  final ValueChanged<bool> onToggle6Hours;
  final TextEditingController rate6HoursController;

  final bool enable24Hours;
  final ValueChanged<bool> onToggle24Hours;
  final TextEditingController rate24HoursController;

  final bool enableWeekly;
  final ValueChanged<bool> onToggleWeekly;
  final TextEditingController rateWeeklyController;

  final bool enableMonthly;
  final ValueChanged<bool> onToggleMonthly;
  final TextEditingController rateMonthlyController;

  // Audit §5 finish (O07): the Out-City day rate. The In-City day rate IS the 24h
  // package rate, so its row below reuses [rate24HoursController] — one rate,
  // shown in both places. Typing the full-day rate prefills the out-city field while it is empty.
  final TextEditingController outCityDayRateController;

  final bool supportSelfDrive;
  final ValueChanged<bool> onToggleSelfDrive;

  final bool supportWithDriver;
  final ValueChanged<bool> onToggleWithDriver;
  final TextEditingController driverAllowanceController;

  final TextEditingController securityDepositController;
  final TextEditingController advanceDepositController;
  final TextEditingController extraHourChargeController;

  final String fuelPolicy;
  final ValueChanged<String> onFuelPolicyChanged;
  final List<String> fuelPolicies;

  const VehicleRatesStepWidget({
    super.key,
    required this.enable1Hour,
    required this.onToggle1Hour,
    required this.rate1HourController,
    required this.enable3Hours,
    required this.onToggle3Hours,
    required this.rate3HoursController,
    required this.enable6Hours,
    required this.onToggle6Hours,
    required this.rate6HoursController,
    required this.enable24Hours,
    required this.onToggle24Hours,
    required this.rate24HoursController,
    required this.enableWeekly,
    required this.onToggleWeekly,
    required this.rateWeeklyController,
    required this.enableMonthly,
    required this.onToggleMonthly,
    required this.rateMonthlyController,
    required this.outCityDayRateController,
    required this.supportSelfDrive,
    required this.onToggleSelfDrive,
    required this.supportWithDriver,
    required this.onToggleWithDriver,
    required this.driverAllowanceController,
    required this.securityDepositController,
    required this.advanceDepositController,
    required this.extraHourChargeController,
    required this.fuelPolicy,
    required this.onFuelPolicyChanged,
    required this.fuelPolicies,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.addVehicleDurationPackages, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(l10n.addVehicleDurationPackagesHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),

        _packageRow(context, l10n.addVehicleRate1Hour, rate1HourController, enable1Hour, onToggle1Hour),
        _packageRow(context, l10n.addVehicleRate3Hours, rate3HoursController, enable3Hours, onToggle3Hours),
        _packageRow(context, l10n.addVehicleRate6Hours, rate6HoursController, enable6Hours, onToggle6Hours),
        _packageRow(context, l10n.addVehicleRateFullDay, rate24HoursController, enable24Hours, onToggle24Hours, onChanged: (v) { if (outCityDayRateController.text.isEmpty) outCityDayRateController.text = v; }),
        _packageRow(context, l10n.addVehicleRateWeekly, rateWeeklyController, enableWeekly, onToggleWeekly),
        _packageRow(context, l10n.addVehicleRateMonthly, rateMonthlyController, enableMonthly, onToggleMonthly),
        const SizedBox(height: 16),

        Text(l10n.addVehicleCityRatesTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(l10n.addVehicleCityRatesHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _policyInput(context, l10n.addVehicleInCityDayRate, l10n.addVehicleInCityDayRateHint, rate24HoursController, onChanged: (v) { if (outCityDayRateController.text.isEmpty) outCityDayRateController.text = v; }),
                const Divider(height: 20),
                _policyInput(context, l10n.addVehicleOutCityDayRate, l10n.addVehicleOutCityDayRateHint, outCityDayRateController),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(l10n.addVehicleServiceType, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Overflow hardening: the text column must flex (hint ~620px wide at 360px/1.35× otherwise).
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.addVehicleSelfDriveService, style: Theme.of(context).textTheme.bodyMedium),
                          Text(l10n.addVehicleSelfDriveHint, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                    Switch(value: supportSelfDrive, activeThumbColor: AppColors.secondary, onChanged: onToggleSelfDrive),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.addVehicleWithDriverService, style: Theme.of(context).textTheme.bodyMedium),
                          Text(l10n.addVehicleWithDriverHint, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                    Switch(value: supportWithDriver, activeThumbColor: AppColors.secondary, onChanged: onToggleWithDriver),
                  ],
                ),
                if (supportWithDriver) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(l10n.addVehicleDriverAllowance, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: driverAllowanceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            // Audit 2026-11-15 DS-10: localized prefix.
                            prefixText: l10n.currencyPrefix,
                            prefixStyle: const TextStyle(fontWeight: FontWeight.w500),
                            suffixText: l10n.addVehiclePerDaySuffix,
                            suffixStyle: Theme.of(context).textTheme.labelSmall,
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(l10n.addVehicleDepositPolicies, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _policyInput(context, l10n.addVehicleSecurityDepositSelfDrive, l10n.addVehicleSecurityDepositHint, securityDepositController),
                const Divider(height: 20),
                _policyInput(context, l10n.addVehicleAdvanceFee, l10n.addVehicleAdvanceHint, advanceDepositController),
                const Divider(height: 20),
                _policyInput(context, l10n.addVehicleExtraHourCharge, l10n.addVehicleExtraHourHint, extraHourChargeController, suffix: l10n.addVehiclePerHourSuffix),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.addVehicleFuelPolicy, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                          Text(l10n.addVehicleFuelPolicyHint, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          value: fuelPolicy,
                          items: fuelPolicies.map((f) => DropdownMenuItem(value: f, child: Text(f, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)))).toList(),
                          onChanged: (v) { if (v != null) onFuelPolicyChanged(v); },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _packageRow(BuildContext context, String label, TextEditingController controller, bool isEnabled, ValueChanged<bool> onToggle, {ValueChanged<String>? onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEnabled ? AppColors.secondary.withValues(alpha: 0.3) : Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Checkbox(value: isEnabled, activeColor: AppColors.secondary, onChanged: (v) => onToggle(v ?? false)),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isEnabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant))),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              enabled: isEnabled,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isEnabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
              decoration: InputDecoration(
                // Audit 2026-11-15 DS-10: localized currency prefix.
                prefixText: AppLocalizations.of(context)!.currencyPrefix,
                prefixStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: isEnabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: isEnabled ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyInput(BuildContext context, String label, String subtitle, TextEditingController controller, {String? suffix, ValueChanged<String>? onChanged}) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              // Audit 2026-11-15 DS-10: localized currency prefix.
              prefixText: AppLocalizations.of(context)!.currencyPrefix,
              prefixStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
              suffixText: suffix,
              suffixStyle: Theme.of(context).textTheme.labelSmall,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            ),
          ),
        ),
      ],
    );
  }
}

