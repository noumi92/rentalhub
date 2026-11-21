import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../services/dues_collection_service.dart';

/// Item 6 (2026-11-21): the "dues paid later" sheet. The amount
/// defaults to the booking's full remaining due, is editable, and
/// is clamped to the due on confirm; the method chips follow the
/// walk-in / handover payment steps (cash / jazzcash / easypaisa /
/// bank_transfer), and "Mark Payment Received" records the
/// payment. Pops with the amount actually collected (0 when the
/// due was already cleared), or null when dismissed. A failed
/// record keeps the sheet open with an error — the payment is
/// never silently dropped.
class DuesCollectSheet extends StatefulWidget {
  final BookingEntity booking;

  const DuesCollectSheet({super.key, required this.booking});

  @override
  State<DuesCollectSheet> createState() => _DuesCollectSheetState();
}

class _DuesCollectSheetState extends State<DuesCollectSheet> {
  static const List<String> methods = [
    'cash',
    'jazzcash',
    'easypaisa',
    'bank_transfer',
  ];

  late final TextEditingController _amountController;
  String _method = 'cash';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: '${widget.booking.remainingBalance}');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

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

  Future<void> _confirm() async {
    final due = widget.booking.remainingBalance;
    final amount =
        (int.tryParse(_amountController.text.trim()) ?? 0).clamp(0, due);
    if (amount <= 0 || _submitting) return;
    setState(() => _submitting = true);
    try {
      final updated = await DuesCollectionService.collectDue(
        booking: widget.booking,
        amount: amount,
        paymentMethod: _method,
      );
      if (!mounted) return;
      Navigator.of(context)
          .pop(widget.booking.remainingBalance - updated.remainingBalance);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppFeedback.showError(
          context, AppLocalizations.of(context)!.financeDuesCollectFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.financeDuesCollectTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${booking.bookingId} • ${booking.customerName ?? l10n.requestsCustomerFallback}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.returnFareTotalDue,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text(l10n.amountRs(formatRs(booking.remainingBalance)),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('dues-collect-amount'),
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.returnPaymentAmountLabel,
                hintText: l10n.returnPaymentAmountHint,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: methods
                  .map((m) => ChoiceChip(
                        label: Text(_methodLabel(l10n, m)),
                        selected: _method == m,
                        onSelected: _submitting
                            ? null
                            : (v) {
                                if (v) setState(() => _method = m);
                              },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DebouncedButton(
                text: l10n.returnPaymentMarkReceived,
                icon: Icons.payments_rounded,
                isLoading: _submitting,
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
