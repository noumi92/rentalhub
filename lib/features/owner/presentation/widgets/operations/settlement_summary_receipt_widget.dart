import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class SettlementSummaryReceiptWidget extends StatelessWidget {
  final int totalKm;
  final int excessKm;
  final int excessKmPenalty;
  final int fuelDeficitFee;
  final int overtimeFee;
  final int securityDeposit;
  final int netRefund;

  const SettlementSummaryReceiptWidget({
    super.key,
    required this.totalKm,
    required this.excessKm,
    required this.excessKmPenalty,
    required this.fuelDeficitFee,
    required this.overtimeFee,
    required this.securityDeposit,
    required this.netRefund,
  });

  @override
  Widget build(BuildContext context) {
    final totalDeductions = excessKmPenalty + fuelDeficitFee + overtimeFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deposit & Return Balance Settlement',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
          ),
          const SizedBox(height: 12),
          _itemRow('Total Kilometers Driven', '$totalKm KM'),
          _itemRow('Allowed KM Allowance', '${totalKm - excessKm} KM'),
          if (excessKm > 0)
            _itemRow('Excess KM Penalty ($excessKm km × Rs. 25)', 'Rs. $excessKmPenalty', isDeduction: true),
          if (fuelDeficitFee > 0)
            _itemRow('Fuel Level Deficit', 'Rs. $fuelDeficitFee', isDeduction: true),
          if (overtimeFee > 0)
            _itemRow('Late Overtime Fee', 'Rs. $overtimeFee', isDeduction: true),
          const Divider(height: 18),
          _itemRow('Initial Security Deposit Held', 'Rs. $securityDeposit'),
          _itemRow('Total Incident / Penalty Deductions', '- Rs. $totalDeductions', isDeduction: true),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Refund to Customer',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.midnightNavy),
              ),
              Text(
                'Rs. $netRefund',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: netRefund >= 0 ? AppColors.emeraldGreen : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(String label, String value, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDeduction ? Colors.red.shade700 : AppColors.midnightNavy,
            ),
          ),
        ],
      ),
    );
  }
}
