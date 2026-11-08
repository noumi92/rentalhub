import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// Phase B (D3): the owner checks a submitted payment proof — the
/// screenshot and the transaction id — and either confirms the
/// payment (booking becomes paid and the handover can start) or
/// rejects it with a reason, sending the booking back to 'approved'
/// so the customer can upload a fresh proof.
class OwnerPaymentVerificationView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerPaymentVerificationView({
    super.key,
    required this.booking,
    this.onBack,
  });

  @override
  State<OwnerPaymentVerificationView> createState() =>
      _OwnerPaymentVerificationViewState();
}

class _OwnerPaymentVerificationViewState
    extends State<OwnerPaymentVerificationView> {
  bool _processing = false;

  BookingEntity get _booking => widget.booking;

  Future<void> _approve() async {
  final l10n = AppLocalizations.of(context)!;
    setState(() => _processing = true);
    try {
      await sl<BookingRemoteDataSource>().verifyPayment(
        bookingId: _booking.bookingId,
        advanceAmount: _booking.advanceRequired,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context,
          l10n.paymentVerificationConfirmed(_booking.bookingId));
      context.push(
        RouteNames.ownerHandover.replaceFirst(':id', _booking.bookingId),
      );
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.paymentVerificationConfirmFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
  final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.paymentVerificationRejectTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.paymentVerificationRejectNote),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.paymentVerificationReasonLabel,
                hintText: l10n.paymentVerificationReasonHint,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(reasonController.text.trim()),
            child: Text(l10n.paymentVerificationRejectButton),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _processing = true);
    try {
      await sl<BookingRemoteDataSource>().rejectPaymentProof(
        bookingId: _booking.bookingId,
        reason: reason,
      );
      if (!mounted) return;
      AppFeedback.showInfo(
          context, l10n.paymentVerificationRejected);
      context.pop();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.paymentVerificationRejectFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final b = _booking;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.paymentVerificationTitle,
              subtitle: l10n.paymentVerificationBooking(b.bookingId),
              onBack: widget.onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _row(l10n.summaryVehicle, b.vehicleName ?? b.vehicleId),
                            _row(l10n.requestsCustomerFallback, b.customerName ?? b.customerId),
                            _row(l10n.editPhone, b.customerPhone ?? '—'),
                            _row(l10n.packageLabel, b.packageType),
                            _row(l10n.paymentVerificationTotalRent, l10n.amountRs(b.totalAmount)),
                            _row(l10n.paymentVerificationAdvanceDue, l10n.amountRs(b.advanceRequired)),
                            _row(l10n.paymentVerificationAdvancePaid, l10n.amountRs(b.advancePaid)),
                            _row(l10n.paymentVerificationTransactionId, b.transactionId ?? '—'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(l10n.paymentVerificationScreenshotTitle, style: Theme.of(context) .textTheme .titleSmall ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (b.paymentProofUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          b.paymentProofUrl!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 120,
                            alignment: Alignment.center,
                            color: AppColors.primaryContainer,
                            child: Text(
                                l10n.paymentVerificationProofUnavailable),
                          ),
                        ),
                      )
                    else
                      Text(l10n.paymentVerificationNoScreenshot),
                    if (b.rejectionReason != null) ...[
                      const SizedBox(height: 14),
                      Text(l10n.paymentVerificationPreviouslyRejected(b.rejectionReason!), style: Theme.of(context) .textTheme .bodyMedium ?.copyWith(color: Colors.orange.shade800)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: DebouncedButton(
                        text: _processing
                            ? l10n.paymentVerificationConfirming
                            : l10n.paymentVerificationConfirmButton(b.advanceRequired),
                        icon: Icons.check_circle_rounded,
                        isLoading: _processing,
                        onPressed: _approve,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : _reject,
                        icon:
                            const Icon(Icons.close_rounded, color: Colors.red),
                        label: Text(l10n.paymentVerificationRejectButton,
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
