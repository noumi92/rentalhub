import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../services/return_settlement_service.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Finish build (O26): the return payment steps — a distinct
/// "Refund Deposit" action that records the refund as its own step
/// (amount included) on `return_settlements/{bookingId}`, followed by
/// a separate "Complete & Close Booking" step. Close stays disabled
/// until the refund step is recorded, so a booking can never be
/// closed with the refund unrecorded. The widget owns the refund
/// state (it restores a refund recorded in an earlier session) so the
/// return view keeps its existing finalize flow untouched: closing
/// still runs the view's finalize, which settles the deposit record,
/// completes the booking and restores the vehicle.
class ReturnPaymentSteps extends StatefulWidget {
  final String bookingId;
  final String? shopId;
  final String? customerId;

  /// The net refund from the live settlement breakdown — the amount
  /// the refund step records. Never invented: it comes from the
  /// view's calculator, not from a fallback.
  final int netRefund;
  final bool isFinalizing;
  final VoidCallback onCompleteClose;

  /// PW-21: what the customer still owes when the deductions exceed
  /// the deposit (SettlementBreakdown.amountOwed). 0 hides the step.
  final int amountOwed;

  const ReturnPaymentSteps({
    super.key,
    required this.bookingId,
    this.shopId,
    this.customerId,
    required this.netRefund,
    required this.isFinalizing,
    required this.onCompleteClose,
    this.amountOwed = 0,
  });

  @override
  State<ReturnPaymentSteps> createState() => _ReturnPaymentStepsState();
}

class _ReturnPaymentStepsState extends State<ReturnPaymentSteps> {
  bool _refundRecorded = false;
  int _refundAmount = 0;
  bool _isRecordingRefund = false;
  // PW-21: the owed-amount collection, persisted on the settlement
  // doc via [ReturnSettlementService.recordOwedCollected] (and
  // restored on open) — no longer in-session only.
  int _owedCollected = 0;
  String? _owedMethod;
  String _owedMethodPick = 'cash';
  bool _isRecordingOwed = false;

  @override
  void initState() {
    super.initState();
    _loadRefundState();
  }

  Future<void> _loadRefundState() async {
    final state =
        await ReturnSettlementService.loadRefundState(widget.bookingId);
    final owed =
        await ReturnSettlementService.loadOwedState(widget.bookingId);
    if (mounted) {
      setState(() {
        _refundRecorded = state.recorded;
        _refundAmount = state.amount;
        if (owed.collected) {
          _owedCollected = owed.amount;
          _owedMethod = owed.method;
        }
      });
    }
  }

  Future<void> _recordRefund() async {
    if (_isRecordingRefund || _refundRecorded) return;
    setState(() => _isRecordingRefund = true);
    try {
      await ReturnSettlementService.recordRefund(
        bookingId: widget.bookingId,
        amount: widget.netRefund,
        shopId: widget.shopId,
        customerId: widget.customerId,
      );
      if (!mounted) return;
      setState(() {
        _refundRecorded = true;
        _refundAmount = widget.netRefund;
      });
      AppFeedback.showSuccess(
        context,
        AppLocalizations.of(context)!
            .returnRefundRecorded(formatRs(_refundAmount)),
      );
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          AppLocalizations.of(context)!.returnRefundFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isRecordingRefund = false);
    }
  }

  Future<void> _markOwedReceived() async {
    if (_isRecordingOwed || _owedCollected > 0) return;
    setState(() => _isRecordingOwed = true);
    try {
      await ReturnSettlementService.recordOwedCollected(
        bookingId: widget.bookingId,
        amount: widget.amountOwed,
        method: _owedMethodPick,
        shopId: widget.shopId,
        customerId: widget.customerId,
      );
      if (!mounted) return;
      setState(() {
        _owedCollected = widget.amountOwed;
        _owedMethod = _owedMethodPick;
      });
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          AppLocalizations.of(context)!.returnOwedRecordFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isRecordingOwed = false);
    }
  }

  Future<void> _undoOwed() async {
    if (_isRecordingOwed || _owedCollected == 0) return;
    setState(() => _isRecordingOwed = true);
    try {
      await ReturnSettlementService.recordOwedCollected(
        bookingId: widget.bookingId,
        amount: 0,
      );
      if (!mounted) return;
      setState(() {
        _owedCollected = 0;
        _owedMethod = null;
      });
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          AppLocalizations.of(context)!.returnOwedRecordFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isRecordingOwed = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canClose = _refundRecorded || widget.netRefund == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.netRefund > 0) ...[
          if (_refundRecorded) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppCardDecoration.shadow(context),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.returnRefundRecorded(formatRs(_refundAmount)),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            _row(context, l10n.returnRefundDeposit,
                l10n.amountRs(formatRs(widget.netRefund))),
            const SizedBox(height: 12),
            DebouncedButton(
              text: _isRecordingRefund
                  ? l10n.returnRecordingRefund
                  : l10n.returnRefundDeposit,
              icon: Icons.account_balance_wallet_rounded,
              isLoading: _isRecordingRefund,
              onPressed: _recordRefund,
            ),
            const SizedBox(height: 12),
          ],
        ],
        // PW-21: the customer-owes step — the receipt used to clamp
        // the refund at zero and the excess simply disappeared. The
        // row shows what is owed; the method chips + Mark received
        // record its collection, mirroring the fare section. The
        // record persists on the settlement doc via
        // [ReturnSettlementService.recordOwedCollected] (and is
        // restored on open), so closing the screen no longer loses it.
        if (widget.amountOwed > 0) ...[
          const SizedBox(height: 12),
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
                Text(
                  l10n.returnAmountOwedByCustomer(
                      l10n.amountRs(formatRs(widget.amountOwed))),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.error),
                ),
                if (_owedCollected > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.returnOwedCollected(
                              l10n.amountRs(formatRs(_owedCollected)),
                              _methodLabel(l10n, _owedMethod ?? 'cash')),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _undoOwed,
                        child: Text(l10n.returnPaymentUndo),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['cash', 'jazzcash', 'easypaisa', 'bank_transfer']
                        .map((m) => ChoiceChip(
                              label: Text(_methodLabel(l10n, m)),
                              selected: _owedMethodPick == m,
                              onSelected: (v) {
                                if (v) setState(() => _owedMethodPick = m);
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  DebouncedButton(
                    text: l10n.returnPaymentMarkReceived,
                    icon: Icons.payments_rounded,
                    onPressed: _markOwedReceived,
                  ),
                ],
              ],
            ),
          ),
        ],
        // Close is a separate step after the refund is recorded — a
        // disabled button (same pattern as the contract view's
        // pre-handover Proceed) rather than a hidden one, so the
        // owner can see what comes next.
        if (canClose)
          DebouncedButton(
            text: widget.isFinalizing
                ? l10n.returnFinalizing
                : l10n.returnCloseBooking,
            icon: Icons.check_circle_rounded,
            isLoading: widget.isFinalizing,
            onPressed: widget.onCompleteClose,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(l10n.returnCloseBooking),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              // AC-11: the disabled button now says why — the
              // contract-view pattern (disabled button + reason line).
              const SizedBox(height: 6),
              Text(
                l10n.returnCloseBookingHint,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
