import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';

/// O23: step 3 — payment + deposit. Money lines Rent / Driver /
/// Discount / Total (total is net of the discount); the amount paid
/// now with method chips (Cash / JazzCash / EasyPaisa / Bank); the
/// security deposit (amount prefilled from the vehicle's
/// securityDepositPkr, its own method, and a Received toggle — off
/// means no deposit is recorded); and the remaining dues line with
/// the "add to dues" toggle.
///
/// Dues wiring: there is no separate dues ledger — the dues screen
/// derives dues from bookings in an approved/paid/active/completed
/// status with a remaining balance. Toggle ON (default) leaves the
/// remainder on the booking, so it appears in dues; toggle OFF
/// requires the full amount paid now (the wizard blocks Next
/// otherwise). All money state lives in the wizard; this widget
/// only renders it.
class ManualBookingPaymentStep extends StatelessWidget {
  const ManualBookingPaymentStep({
    super.key,
    required this.rentAmount,
    required this.driverAmount,
    required this.discountController,
    required this.discountError,
    required this.onDiscountChanged,
    required this.advanceController,
    required this.advanceError,
    required this.onAdvanceChanged,
    required this.advanceRequired,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.depositController,
    required this.depositReceived,
    required this.onDepositReceivedChanged,
    required this.depositMethod,
    required this.onDepositMethodChanged,
    required this.remainingDues,
    required this.addToDues,
    required this.onAddToDuesChanged,
  });

  final int rentAmount;
  final int driverAmount;
  final TextEditingController discountController;
  final String? discountError;
  final VoidCallback onDiscountChanged;
  final TextEditingController advanceController;
  final String? advanceError;
  final VoidCallback onAdvanceChanged;
  final int advanceRequired;
  final String paymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;
  final TextEditingController depositController;
  final bool depositReceived;
  final ValueChanged<bool> onDepositReceivedChanged;
  final String depositMethod;
  final ValueChanged<String> onDepositMethodChanged;
  final int remainingDues;
  final bool addToDues;
  final ValueChanged<bool> onAddToDuesChanged;

  static const List<String> methods = ['cash', 'jazzcash', 'easypaisa', 'bank_transfer'];

  int get _discount => (int.tryParse(discountController.text.trim()) ?? 0).clamp(0, 1 << 30);
  int get _total => (rentAmount + driverAmount - _discount).clamp(0, 1 << 30);

  String _methodLabel(AppLocalizations l10n, String method) {
    switch (method) {
      case 'jazzcash':
        return l10n.returnPaymentJazzCash;
      case 'easypaisa':
        return l10n.returnPaymentEasyPaisa;
      case 'bank_transfer':
        return l10n.returnPaymentBankTransfer;
      default:
        return l10n.returnPaymentCash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _row(context, l10n, l10n.manualBookingRentLine, rentAmount),
                _row(context, l10n, l10n.manualBookingDriverLine, driverAmount),
                _discountRow(context, l10n),
                const Divider(height: 20),
                _row(context, l10n, l10n.bookingFareTotal, _total, bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.manualBookingPaidNow, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('${l10n.bookingFareAdvanceRequired}: ${l10n.amountRs(formatRs(advanceRequired))}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        _amountField(context, controller: advanceController, label: l10n.bookingCheckAdvance, errorText: advanceError, onChanged: (_) => onAdvanceChanged()),
        const SizedBox(height: 10),
        _methodChips(context, l10n, selected: paymentMethod, onChanged: onPaymentMethodChanged),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(l10n.manualBookingDepositReceived, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
            Switch(value: depositReceived, onChanged: onDepositReceivedChanged),
          ],
        ),
        if (depositReceived) ...[
          _amountField(context, controller: depositController, label: l10n.manualBookingDepositLabel, onChanged: (_) {}),
          const SizedBox(height: 10),
          Text(l10n.manualBookingDepositMethod, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          _methodChips(context, l10n, selected: depositMethod, onChanged: onDepositMethodChanged),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(l10n.manualBookingRemainingDues, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
            Text(l10n.amountRs(formatRs(remainingDues)), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(l10n.manualBookingAddToDues, style: Theme.of(context).textTheme.bodyMedium)),
            Switch(value: addToDues, onChanged: onAddToDuesChanged),
          ],
        ),
      ],
    );
  }

  Widget _discountRow(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.manualBookingDiscountLine, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: TextField(
              key: const Key('manual-booking-discount'),
              controller: discountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => onDiscountChanged(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: l10n.manualBookingDiscountHint,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                errorText: discountError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountField(BuildContext context, {required TextEditingController controller, required String label, String? errorText, required ValueChanged<String> onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.payments_rounded, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        errorText: errorText,
      ),
    );
  }

  Widget _methodChips(BuildContext context, AppLocalizations l10n, {required String selected, required ValueChanged<String> onChanged}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) => ChoiceChip(label: Text(_methodLabel(l10n, m)), selected: selected == m, onSelected: (v) { if (v) onChanged(m); })).toList(),
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, String label, int amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(l10n.amountRs(formatRs(amount)), style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
}
