import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';

class SettlementSummaryReceiptWidget extends StatelessWidget {
  final int totalKm;
  final int excessKm;
  final int excessKmPenalty;
  final int extraKmRate;
  final int fuelDeficitFee;
  final int overtimeFee;
  final int damageCharge;
  final int securityDeposit;
  final int netRefund;

  const SettlementSummaryReceiptWidget({
    super.key,
    required this.totalKm,
    required this.excessKm,
    required this.excessKmPenalty,
    this.extraKmRate = 25,
    required this.fuelDeficitFee,
    required this.overtimeFee,
    this.damageCharge = 0,
    required this.securityDeposit,
    required this.netRefund,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final totalDeductions =
        excessKmPenalty + fuelDeficitFee + overtimeFee + damageCharge;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.returnReceiptTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _itemRow(context, l10n.returnReceiptTotalKm, '$totalKm KM'),
          _itemRow(context, l10n.returnReceiptAllowance, '${totalKm - excessKm} KM'),
          if (excessKm > 0)
            _itemRow(context, l10n.returnReceiptExcessPenalty(excessKm, extraKmRate), l10n.amountRs(excessKmPenalty), isDeduction: true),
          if (fuelDeficitFee > 0)
            _itemRow(context, l10n.returnReceiptFuelDeficit, l10n.amountRs(fuelDeficitFee), isDeduction: true),
          if (overtimeFee > 0)
            _itemRow(context, l10n.returnReceiptOvertime, l10n.amountRs(overtimeFee), isDeduction: true),
          if (damageCharge > 0)
            _itemRow(context, l10n.returnReceiptDamage, l10n.amountRs(damageCharge), isDeduction: true),
          const Divider(height: 18),
          _itemRow(context, l10n.returnReceiptDepositHeld, l10n.amountRs(securityDeposit)),
          _itemRow(context, l10n.returnReceiptTotalDeductions, l10n.returnReceiptDeductionsAmount(totalDeductions), isDeduction: true),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.returnReceiptNetRefund,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                l10n.amountRs(netRefund),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: netRefund >= 0 ? AppColors.successTextFor(Theme.of(context).brightness) : AppColors.dangerTextFor(Theme.of(context).brightness),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, String label, String value, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDeduction ? AppColors.dangerTextFor(Theme.of(context).brightness) : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

