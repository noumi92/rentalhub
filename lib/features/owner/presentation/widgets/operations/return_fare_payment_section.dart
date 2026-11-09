import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// Audit item 5 (O26): the settlement fare table (Rent / Advance /
/// Remaining / Total Due) plus the "Payment Received" step — the
/// remaining rent collected at return, with a payment-method picker
/// (Cash / Bank Transfer / JazzCash / EasyPaisa). Reports the
/// collection to the owning view via [onCollected]; collecting never
/// changes the deposit arithmetic, it only reduces the amount due.
class ReturnFarePaymentSection extends StatefulWidget {
  final BookingEntity booking;
  final void Function(int amount, String? method) onCollected;

  const ReturnFarePaymentSection({
    super.key,
    required this.booking,
    required this.onCollected,
  });

  @override
  State<ReturnFarePaymentSection> createState() =>
      _ReturnFarePaymentSectionState();
}

class _ReturnFarePaymentSectionState extends State<ReturnFarePaymentSection> {
  static const List<String> methods = [
    'cash',
    'bank_transfer',
    'jazzcash',
    'easypaisa',
  ];

  late final TextEditingController _amountController;
  String _method = 'cash';
  int _collected = 0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: '${widget.booking.remainingBalance}');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _amount =>
      (int.tryParse(_amountController.text.trim()) ?? 0).clamp(0, 1 << 30);
  int get _totalDue =>
      (widget.booking.remainingBalance - _collected).clamp(0, 1 << 30);

  void _markReceived() {
    final amount = _amount.clamp(0, widget.booking.remainingBalance);
    setState(() => _collected = amount);
    widget.onCollected(amount, _method);
  }

  void _undo() {
    setState(() {
      _collected = 0;
      _amountController.text = '${widget.booking.remainingBalance}';
    });
    widget.onCollected(0, null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;
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
            l10n.returnFareTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          _row(context, l10n.returnFareRent,
              l10n.amountRs(formatRs(booking.totalAmount))),
          _row(context, l10n.returnFareAdvancePaid,
              l10n.amountRs(formatRs(booking.advancePaid))),
          _row(context, l10n.returnFareRemaining,
              l10n.amountRs(formatRs(booking.remainingBalance))),
          const Divider(height: 18),
          _row(context, l10n.returnFareTotalDue, l10n.amountRs(formatRs(_totalDue)),
              bold: true),
          const SizedBox(height: 16),
          Text(
            l10n.returnPaymentTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: methods.map((m) {
              return ChoiceChip(
                label: Text(_methodLabel(l10n, m)),
                selected: _method == m,
                onSelected: _collected > 0
                    ? null
                    : (v) {
                        if (v) setState(() => _method = m);
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_collected > 0) ...[
            _row(context, l10n.returnPaymentReceived,
                l10n.amountRs(formatRs(_collected)),
                bold: true),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _undo,
                child: Text(l10n.returnPaymentUndo),
              ),
            ),
          ] else ...[
            TextField(
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
            DebouncedButton(
              text: l10n.returnPaymentMarkReceived,
              icon: Icons.payments_rounded,
              onPressed: _markReceived,
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(l10n.returnPaymentRecordExtraCharges),
              onPressed: () => context.push(
                RouteNames.ownerRecordExtraCharges
                    .replaceFirst(':id', widget.booking.bookingId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(AppLocalizations l10n, String method) {
    switch (method) {
      case 'bank_transfer':
        return l10n.returnPaymentBankTransfer;
      case 'jazzcash':
        return l10n.returnPaymentJazzCash;
      case 'easypaisa':
        return l10n.returnPaymentEasyPaisa;
      default:
        return l10n.returnPaymentCash;
    }
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          bold ? FontWeight.w800 : FontWeight.w600,
                    )),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
        ],
      ),
    );
  }
}
