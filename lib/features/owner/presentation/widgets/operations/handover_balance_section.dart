import 'package:flutter/material.dart';

import '../../../../../core/theme/card_decoration.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// PW-16 / PW-17: the handover money rows, rendered ABOVE the
/// signature pads so the owner sees them before certifying.
///
/// The balance due (total − advance, from the booking) plus how it
/// was collected — Cash / JazzCash / EasyPaisa / Bank Transfer /
/// Not yet — and the security deposit already loaded for the
/// vehicle. The method starts unselected: certifying with no method
/// picked is blocked by the owning view, so an unrecorded balance
/// cannot be certified silently. Extracted from
/// [OwnerHandoverSignatureView] so the view stays under the
/// 250-line cap.
///
/// Item 9 (O27): the advance is now its own row (it used to be
/// implicit in the balance maths), EasyPaisa joins the method
/// chips, and both the balance and the deposit get a method +
/// "Received" toggle. The deposit amount comes from the vehicle's
/// `securityDepositPkr` — never a hardcoded figure. The optional
/// params default to the old behaviour, so the legacy single-view
/// and the return flow keep compiling unchanged.
class HandoverBalanceSection extends StatelessWidget {
  const HandoverBalanceSection({
    super.key,
    required this.balanceDue,
    required this.securityDeposit,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.advancePaid = 0,
    this.depositMethod,
    this.onDepositMethodChanged,
    this.depositReceived = false,
    this.onDepositReceivedChanged,
    this.balanceReceived = false,
    this.onBalanceReceivedChanged,
  });

  /// Total − advance, clamped at zero. 0 means nothing is due.
  final int balanceDue;

  /// The vehicle's security deposit, loaded by the owning view.
  final int securityDeposit;

  /// 'cash' | 'jazzcash' | 'easypaisa' | 'bank_transfer' | 'not_yet',
  /// or null when the owner has not picked one yet.
  final String? selectedMethod;

  final ValueChanged<String> onMethodChanged;

  /// Advance already paid online — shown as its own row (O27).
  final int advancePaid;

  /// How the deposit was collected ('cash' | 'jazzcash' |
  /// 'easypaisa' | 'bank_transfer'), or null when not picked yet.
  final String? depositMethod;
  final ValueChanged<String>? onDepositMethodChanged;

  /// Whether the deposit was actually received (the toggle).
  final bool depositReceived;
  final ValueChanged<bool>? onDepositReceivedChanged;

  /// Whether the balance was actually received (the toggle).
  final bool balanceReceived;
  final ValueChanged<bool>? onBalanceReceivedChanged;

  static const List<String> methods = [
    'cash',
    'jazzcash',
    'easypaisa',
    'bank_transfer',
    'not_yet',
  ];

  /// Deposit methods exclude 'not_yet' — the deposit is either
  /// collected by a method or not collected at all.
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppCardDecoration.shadow(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // O27: the advance is explicit — "Advance (paid online)
              // Rs 1,000 ✓" — instead of hidden inside the balance.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text(l10n.handoverWizardAdvancePaid,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium)),
                  const SizedBox(width: 8),
                  Text(l10n.amountRs(formatRs(advancePaid)),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text(l10n.handoverBalanceDue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium)),
                  const SizedBox(width: 8),
                  Text(l10n.amountRs(formatRs(balanceDue)),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.returnPaymentMethod,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: methods
                    .map((m) => ChoiceChip(
                          label: Text(_methodLabel(l10n, m)),
                          selected: selectedMethod == m,
                          onSelected: (v) {
                            if (v) onMethodChanged(m);
                          },
                        ))
                    .toList(),
              ),
              if (onBalanceReceivedChanged != null) ...[
                const SizedBox(height: 4),
                // A ListTile inside the section's decorated Container
                // asserts in debug builds — give it its own
                // transparent Material (same as HandoverChecklistSection).
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(l10n.handoverWizardBalanceReceived,
                        style: Theme.of(context).textTheme.bodyMedium),
                    value: balanceReceived,
                    onChanged: onBalanceReceivedChanged,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppCardDecoration.shadow(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Text(l10n.returnReceiptDepositHeld,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium)),
                  const SizedBox(width: 8),
                  Text(l10n.amountRs(formatRs(securityDeposit)),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
              if (onDepositMethodChanged != null) ...[
                const SizedBox(height: 8),
                Text(l10n.handoverWizardDepositMethod,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: depositMethods
                      .map((m) => ChoiceChip(
                            label: Text(_methodLabel(l10n, m)),
                            selected: depositMethod == m,
                            onSelected: (v) {
                              if (v) onDepositMethodChanged!(m);
                            },
                          ))
                      .toList(),
                ),
              ],
              if (onDepositReceivedChanged != null) ...[
                const SizedBox(height: 4),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(l10n.handoverWizardDepositReceived,
                        style: Theme.of(context).textTheme.bodyMedium),
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
