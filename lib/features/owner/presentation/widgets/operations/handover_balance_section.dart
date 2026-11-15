import 'package:flutter/material.dart';

import '../../../../../core/theme/card_decoration.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// PW-16 / PW-17: the handover money rows, rendered ABOVE the
/// signature pads so the owner sees them before certifying.
///
/// The balance due (total − advance, from the booking) plus how it
/// was collected — Cash / JazzCash / Bank Transfer / Not yet — and
/// the security deposit already loaded for the vehicle. The method
/// starts unselected: certifying with no method picked is blocked by
/// the owning view, so an unrecorded balance cannot be certified
/// silently. Extracted from [OwnerHandoverSignatureView] so the view
/// stays under the 250-line cap.
class HandoverBalanceSection extends StatelessWidget {
  const HandoverBalanceSection({
    super.key,
    required this.balanceDue,
    required this.securityDeposit,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  /// Total − advance, clamped at zero. 0 means nothing is due.
  final int balanceDue;

  /// The vehicle's security deposit, loaded by the owning view.
  final int securityDeposit;

  /// 'cash' | 'jazzcash' | 'bank_transfer' | 'not_yet', or null when
  /// the owner has not picked one yet.
  final String? selectedMethod;

  final ValueChanged<String> onMethodChanged;

  static const List<String> methods = [
    'cash',
    'jazzcash',
    'bank_transfer',
    'not_yet',
  ];

  String _methodLabel(AppLocalizations l10n, String method) {
    switch (method) {
      case 'bank_transfer':
        return l10n.returnPaymentBankTransfer;
      case 'jazzcash':
        return l10n.returnPaymentJazzCash;
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
          child: Row(
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
        ),
      ],
    );
  }
}
