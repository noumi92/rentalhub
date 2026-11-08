import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
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
    setState(() => _processing = true);
    try {
      await sl<BookingRemoteDataSource>().verifyPayment(
        bookingId: _booking.bookingId,
        advanceAmount: _booking.advanceRequired,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context,
          'Payment confirmed — booking #${_booking.bookingId} is paid.');
      context.push(
        RouteNames.ownerHandover.replaceFirst(':id', _booking.bookingId),
      );
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Confirmation failed: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject this proof?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'The customer sees this reason and can upload a new proof.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                hintText: 'e.g. Screenshot is unreadable',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(reasonController.text.trim()),
            child: const Text('Reject Proof'),
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
      AppFeedback.showInfo(context,
          'Proof rejected — the customer can upload a new one.');
      context.pop();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Rejection failed: $e');
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
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: widget.onBack ?? () => context.pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verify Payment Proof',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('Booking #${b.bookingId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
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
                            _row('Vehicle',
                                b.vehicleName ?? b.vehicleId),
                            _row('Customer',
                                b.customerName ?? b.customerId),
                            _row('Phone', b.customerPhone ?? '—'),
                            _row('Package', b.packageType),
                            _row('Total rent', 'Rs. ${b.totalAmount}'),
                            _row('Advance due',
                                'Rs. ${b.advanceRequired}'),
                            _row('Advance paid', 'Rs. ${b.advancePaid}'),
                            _row('Transaction ID',
                                b.transactionId ?? '—'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Payment screenshot',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
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
                            child: const Text(
                                'Proof image unavailable — ask the customer to resend it.'),
                          ),
                        ),
                      )
                    else
                      const Text('No screenshot attached.'),
                    if (b.rejectionReason != null) ...[
                      const SizedBox(height: 14),
                      Text('Previously rejected: ${b.rejectionReason}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.orange.shade800)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: DebouncedButton(
                        text: _processing
                            ? 'Confirming…'
                            : 'Confirm Payment — Rs. ${b.advanceRequired}',
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
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.red),
                        label: const Text('Reject Proof',
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
