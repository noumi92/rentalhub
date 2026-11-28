import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../services/walk_in_booking_service.dart';

/// Opens the owner-only payment sheet for a walk-in booking and
/// returns the updated [BookingEntity] when a payment is saved, or
/// null when dismissed.
Future<BookingEntity?> showOwnerAddPaymentSheet(
  BuildContext context, {
  required BookingEntity booking,
}) {
  return showModalBottomSheet<BookingEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _OwnerAddPaymentSheet(booking: booking),
  );
}

class _OwnerAddPaymentSheet extends StatefulWidget {
  final BookingEntity booking;

  const _OwnerAddPaymentSheet({required this.booking});

  @override
  State<_OwnerAddPaymentSheet> createState() => _OwnerAddPaymentSheetState();
}

class _OwnerAddPaymentSheetState extends State<_OwnerAddPaymentSheet> {
  late final TextEditingController _amountController;
  String _method = 'cash';
  bool _saving = false;

  int get _suggestedAmount {
    final b = widget.booking;
    if (b.status == 'approved' && b.advanceRequired > b.advancePaid) {
      return (b.advanceRequired - b.advancePaid).clamp(0, b.remainingBalance);
    }
    return b.remainingBalance;
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _suggestedAmount > 0 ? '$_suggestedAmount' : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      AppFeedback.showError(context, l10n.walkInAddPaymentAmountRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await WalkInBookingService.recordOwnerPayment(
        booking: widget.booking,
        amount: amount,
        paymentMethod: _method,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.walkInAddPaymentSaved);
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, l10n.walkInAddPaymentFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = widget.booking;
    final methods = [
      ('cash', l10n.returnPaymentCash),
      ('bank_transfer', l10n.returnPaymentBankTransfer),
      ('jazzcash', l10n.returnPaymentJazzCash),
      ('easypaisa', l10n.returnPaymentEasyPaisa),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.walkInAddPaymentTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '#${b.bookingId} • ${l10n.bookingFareRemaining}: ${l10n.amountRs(formatRs(b.remainingBalance))}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('walkin_payment_amount_field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.walkInAddPaymentAmountLabel,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in methods)
                ChoiceChip(
                  label: Text(label),
                  selected: _method == value,
                  onSelected: (_) => setState(() => _method = value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DebouncedButton(
            text: l10n.walkInAddPaymentSave,
            icon: Icons.payments_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
