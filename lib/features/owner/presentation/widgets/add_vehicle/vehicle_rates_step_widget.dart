import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration Packages (Hourly & Daily)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
        const SizedBox(height: 4),
        const Text('Enable packages and edit rates in PKR per booking tier.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),

        _packageRow(context, '1 Hour Rate', rate1HourController, enable1Hour, onToggle1Hour),
        _packageRow(context, '3 Hours Rate', rate3HoursController, enable3Hours, onToggle3Hours),
        _packageRow(context, '6 Hours Rate', rate6HoursController, enable6Hours, onToggle6Hours),
        _packageRow(context, 'Full Day (24h) Rate', rate24HoursController, enable24Hours, onToggle24Hours),
        _packageRow(context, 'Weekly (7 Days) Rate', rateWeeklyController, enableWeekly, onToggleWeekly),
        const SizedBox(height: 16),

        const Text('Service Type & Driver Options', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Self-Drive Service', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                        Text('Customer drives the vehicle themselves', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    Switch(value: supportSelfDrive, activeThumbColor: AppColors.sunsetOrange, onChanged: onToggleSelfDrive),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('With-Driver Service', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                        Text('Shop provides experienced chauffeur', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    Switch(value: supportWithDriver, activeThumbColor: AppColors.sunsetOrange, onChanged: onToggleWithDriver),
                  ],
                ),
                if (supportWithDriver) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text('Driver Daily Allowance:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: driverAllowanceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.sunsetOrange, fontSize: 14),
                          decoration: InputDecoration(
                            prefixText: 'Rs. ',
                            prefixStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
                            suffixText: '/day',
                            suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
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

        const Text('Security Deposit & Rental Policies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _policyInput(context, 'Security Deposit (Self-Drive)', 'Refunded on car return in clean condition', securityDepositController),
                const Divider(height: 20),
                _policyInput(context, 'Advance Booking Fee', 'Required up front to lock slot', advanceDepositController),
                const Divider(height: 20),
                _policyInput(context, 'Extra Hour Overstay Charge', 'Billed per hour past scheduled return', extraHourChargeController, suffix: '/hr'),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fuel Policy', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                          Text('Condition expected upon return', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: fuelPolicy,
                          items: fuelPolicies.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)))).toList(),
                          onChanged: (v) {
                            if (v != null) onFuelPolicyChanged(v);
                          },
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

  Widget _packageRow(BuildContext context, String label, TextEditingController controller, bool isEnabled, ValueChanged<bool> onToggle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEnabled ? AppColors.sunsetOrange.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Row(
        children: [
          Checkbox(value: isEnabled, activeColor: AppColors.sunsetOrange, onChanged: (v) => onToggle(v ?? false)),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isEnabled ? AppColors.midnightNavy : AppColors.textMuted))),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              enabled: isEnabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: isEnabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                prefixStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: isEnabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: isEnabled ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyInput(BuildContext context, String label, String subtitle, TextEditingController controller, {String? suffix}) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
              Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 13.5),
            decoration: InputDecoration(
              prefixText: 'Rs. ',
              prefixStyle: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
              suffixText: suffix,
              suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ),
      ],
    );
  }
}

