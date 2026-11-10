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

  /// The net refund from the live settlement breakdown — the amount
  /// the refund step records. Never invented: it comes from the
  /// view's calculator, not from a fallback.
  final int netRefund;
  final bool isFinalizing;
  final VoidCallback onCompleteClose;

  const ReturnPaymentSteps({
    super.key,
    required this.bookingId,
    required this.netRefund,
    required this.isFinalizing,
    required this.onCompleteClose,
  });

  @override
  State<ReturnPaymentSteps> createState() => _ReturnPaymentStepsState();
}

class _ReturnPaymentStepsState extends State<ReturnPaymentSteps> {
  bool _refundRecorded = false;
  int _refundAmount = 0;
  bool _isRecordingRefund = false;

  @override
  void initState() {
    super.initState();
    _loadRefundState();
  }

  Future<void> _loadRefundState() async {
    final state =
        await ReturnSettlementService.loadRefundState(widget.bookingId);
    if (mounted) {
      setState(() {
        _refundRecorded = state.recorded;
        _refundAmount = state.amount;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_refundRecorded) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppCardDecoration.shadow(context)
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.returnRefundRecorded(formatRs(_refundAmount)),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
        // Close is a separate step after the refund is recorded — a
        // disabled button (same pattern as the contract view's
        // pre-handover Proceed) rather than a hidden one, so the
        // owner can see what comes next.
        if (_refundRecorded)
          DebouncedButton(
            text: widget.isFinalizing
                ? l10n.returnFinalizing
                : l10n.returnCloseBooking,
            icon: Icons.check_circle_rounded,
            isLoading: widget.isFinalizing,
            onPressed: widget.onCompleteClose,
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(l10n.returnCloseBooking),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
        ],
      ),
    );
  }
}
