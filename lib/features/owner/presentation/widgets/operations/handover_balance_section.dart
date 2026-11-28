import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/card_decoration.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// Handover payment & security deposit section:
/// - Displays Advance Paid + Balance Due with a Payment Method dropdown
///   and Balance Received confirmation toggle.
/// - Displays Security Deposit with an editable amount field (when
///   [onSecurityDepositChanged] is supplied), a Payment Method dropdown,
///   and a Security Deposit Received confirmation toggle.
class HandoverBalanceSection extends StatelessWidget {
  const HandoverBalanceSection({
    super.key,
    required this.balanceDue,
    required this.securityDeposit,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.advancePaid = 0,
    this.cashReceivedAtHandover = 0,
    this.onCashReceivedChanged,
    this.onSecurityDepositChanged,
    this.depositMethod,
    this.onDepositMethodChanged,
    this.depositReceived = false,
    this.onDepositReceivedChanged,
    this.balanceReceived = false,
    this.onBalanceReceivedChanged,
  });

  final int balanceDue;
  final int securityDeposit;
  final String? selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final int advancePaid;
  final int cashReceivedAtHandover;
  final ValueChanged<int>? onCashReceivedChanged;
  final ValueChanged<int>? onSecurityDepositChanged;
  final String? depositMethod;
  final ValueChanged<String>? onDepositMethodChanged;
  final bool depositReceived;
  final ValueChanged<bool>? onDepositReceivedChanged;
  final bool balanceReceived;
  final ValueChanged<bool>? onBalanceReceivedChanged;

  static const List<String> methods = [
    'cash',
    'jazzcash',
    'easypaisa',
    'bank_transfer',
    'not_yet',
  ];

  static const List<String> depositMethods = [
    'cash',
    'jazzcash',
    'easypaisa',
    'bank_transfer',
  ];

  String _methodLabel(AppLocalizations l10n, String method) {
    switch (method) {
      case 'bank_transfer':
        return l10n.returnPaymentBankTransfer;
      case 'jazzcash':
        return l10n.returnPaymentJazzCash;
      case 'easypaisa':
        return l10n.returnPaymentEasyPaisa;
      case 'not_yet':
        return l10n.handoverBalanceNotYet;
      default:
        return l10n.returnPaymentCash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fillColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      l10n.handoverWizardAdvancePaid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.amountRs(formatRs(advancePaid)),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      l10n.handoverBalanceDue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.amountRs(formatRs(balanceDue)),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (onCashReceivedChanged != null) ...[
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('handover_cash_received_field'),
                  initialValue:
                      cashReceivedAtHandover > 0 ? '$cashReceivedAtHandover' : '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.handoverCashReceivedLabel,
                    hintText: '0',
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v.trim()) ?? 0;
                    onCashReceivedChanged!(parsed);
                  },
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('handover_balance_method_dropdown'),
                initialValue:
                    methods.contains(selectedMethod) ? selectedMethod : null,
                decoration: InputDecoration(
                  labelText: l10n.returnPaymentMethod,
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: methods
                    .map(
                      (m) => DropdownMenuItem<String>(
                        value: m,
                        child: Text(_methodLabel(l10n, m)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onMethodChanged(v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      l10n.returnReceiptDepositHeld,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.amountRs(formatRs(securityDeposit)),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (onSecurityDepositChanged != null) ...[
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('handover_security_deposit_field'),
                  initialValue: '$securityDeposit',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.handoverSecurityAmountLabel,
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v.trim()) ?? 0;
                    onSecurityDepositChanged!(parsed);
                  },
                ),
              ],
              if (onDepositMethodChanged != null) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('handover_deposit_method_dropdown'),
                  initialValue: depositMethods.contains(depositMethod)
                      ? depositMethod
                      : null,
                  decoration: InputDecoration(
                    labelText: l10n.handoverWizardDepositMethod,
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: depositMethods
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m,
                          child: Text(_methodLabel(l10n, m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onDepositMethodChanged!(v);
                  },
                ),
              ],
              if (onDepositReceivedChanged != null) ...[
                const SizedBox(height: 4),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    key: const ValueKey('handover_deposit_received_switch'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      l10n.handoverWizardDepositReceived,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: depositReceived,
                    onChanged: onDepositReceivedChanged,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
