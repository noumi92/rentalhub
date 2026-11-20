import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Audit item 5 (O26): the settlement fare table (Rent / Advance /
/// Remaining / Total Due) plus the "Payment Received" step — the
/// remaining rent collected at return, with a payment-method picker
/// (Cash / Bank Transfer / JazzCash / EasyPaisa). Reports the
/// collection to the owning view via [onCollected]; collecting never
/// changes the deposit arithmetic, it only reduces the amount due.
///
/// Per-km extra fare (2026-11-20): when [extraFareDue] > 0 a second
/// collection row appears for the actual-km fare above the booked
/// estimate, with its own method picker and received state, and
/// reports via [onExtraFareCollected]. The extra fare is rent the
/// trip genuinely earned, so the Total Due counts whatever of it is
/// still uncollected alongside the remaining rent.
class ReturnFarePaymentSection extends StatefulWidget {
  final BookingEntity booking;
  final void Function(int amount, String? method) onCollected;
  final int extraFareDue;
  final void Function(int amount, String? method)? onExtraFareCollected;

  const ReturnFarePaymentSection({
    super.key,
    required this.booking,
    required this.onCollected,
    this.extraFareDue = 0,
    this.onExtraFareCollected,
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

  // Per-km extra fare collection: its own method and amount, so
  // the extra fare never shares state with the remaining rent.
  late final TextEditingController _extraAmountController;
  String _extraMethod = 'cash';
  int _extraCollected = 0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: '${widget.booking.remainingBalance}');
    _extraAmountController =
        TextEditingController(text: '${widget.extraFareDue}');
  }

  @override
  void didUpdateWidget(covariant ReturnFarePaymentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The extra due follows the typed odometer — while nothing is
    // collected yet, keep the amount field on the live due.
    if (widget.extraFareDue != oldWidget.extraFareDue &&
        _extraCollected == 0) {
      _extraAmountController.text = '${widget.extraFareDue}';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _extraAmountController.dispose();
    super.dispose();
  }

  int get _amount =>
      (int.tryParse(_amountController.text.trim()) ?? 0).clamp(0, 1 << 30);
  int get _extraAmount => (int.tryParse(_extraAmountController.text.trim()) ?? 0)
      .clamp(0, 1 << 30);
  int get _totalDue => ((widget.booking.remainingBalance - _collected) +
          (widget.extraFareDue - _extraCollected))
      .clamp(0, 1 << 30);

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

  void _markExtraFareReceived() {
    final amount = _extraAmount.clamp(0, widget.extraFareDue);
    setState(() => _extraCollected = amount);
    widget.onExtraFareCollected?.call(amount, _extraMethod);
  }

  void _undoExtraFare() {
    setState(() {
      _extraCollected = 0;
      _extraAmountController.text = '${widget.extraFareDue}';
    });
    widget.onExtraFareCollected?.call(0, null);
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
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.returnFareTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _row(context, l10n.returnFareRent,
              l10n.amountRs(formatRs(booking.totalAmount))),
          _row(context, l10n.returnFareAdvancePaid,
              l10n.amountRs(formatRs(booking.advancePaid))),
          _row(context, l10n.returnFareRemaining,
              l10n.amountRs(formatRs(booking.remainingBalance))),
          if (widget.extraFareDue > 0)
            _row(context, l10n.returnPerKmExtraDue,
                l10n.amountRs(formatRs(widget.extraFareDue))),
          const Divider(height: 18),
          _row(context, l10n.returnFareTotalDue, l10n.amountRs(formatRs(_totalDue)),
              bold: true),
          const SizedBox(height: 16),
          Text(
            l10n.returnPaymentTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
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
          // Per-km extra fare collection: the same method chips +
          // mark-received pattern as the remaining rent, with its
          // own state — shown only when an extra fare is due.
          if (widget.extraFareDue > 0) ...[
            const SizedBox(height: 16),
            Text(
              l10n.returnExtraFareTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: methods.map((m) {
                return ChoiceChip(
                  label: Text(_methodLabel(l10n, m)),
                  selected: _extraMethod == m,
                  onSelected: _extraCollected > 0
                      ? null
                      : (v) {
                          if (v) setState(() => _extraMethod = m);
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (_extraCollected > 0) ...[
              _row(context, l10n.returnExtraFareReceived,
                  l10n.amountRs(formatRs(_extraCollected)),
                  bold: true),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _undoExtraFare,
                  child: Text(l10n.returnPaymentUndo),
                ),
              ),
            ] else ...[
              TextField(
                controller: _extraAmountController,
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
                onPressed: _markExtraFareReceived,
              ),
            ],
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
                          bold ? FontWeight.w500 : FontWeight.w400,
                    )),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
