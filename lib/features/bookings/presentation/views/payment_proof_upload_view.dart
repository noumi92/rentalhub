import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/queued_upload.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/proof_screenshot_picker.dart';

class PaymentProofUploadView extends StatefulWidget {
  final BookingEntity booking;
  final Function(BookingEntity updatedBooking)? onProofSubmitted;
  final VoidCallback? onBack;

  const PaymentProofUploadView({
    super.key,
    required this.booking,
    this.onProofSubmitted,
    this.onBack,
  });

  @override
  State<PaymentProofUploadView> createState() => _PaymentProofUploadViewState();
}

class _PaymentProofUploadViewState extends State<PaymentProofUploadView> {
  final _tidController = TextEditingController();
  File? _selectedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tidController.dispose();
    super.dispose();
  }

  Future<void> _submitProof() async {
    final tid = _tidController.text.trim();
    if (tid.isEmpty) {
      AppFeedback.showError(context, 'Please enter the transaction reference / TID.');
      return;
    }
    if (_selectedFile == null) {
      AppFeedback.showError(context, 'Please attach your payment screenshot or receipt.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // D2: the proof must really upload. A failed upload is an error
      // the customer sees — never a made-up storage URL filed as their
      // proof for the shop to "verify".
      // Phase B (B3): ...unless the device is offline. Then the
      // receipt is queued and the proof is recorded with its TID —
      // the image follows on sync, and nothing fake is filed.
      final cpanel = sl<CPanelStorageClient>();
      final queue = sl.isRegistered<OfflineSyncQueue>()
          ? sl<OfflineSyncQueue>()
          : null;
      String proofUrl = '';
      try {
        final key = await cpanel.uploadFile(
          file: _selectedFile!,
          userUid: widget.booking.customerId,
          folder: 'payments',
        );
        proofUrl = cpanel.getSignedMediaUrl(key, widget.booking.customerId);
      } catch (_) {
        if (queue == null) rethrow;
        await enqueueUpload(
          file: _selectedFile!,
          userUid: widget.booking.customerId,
          folder: 'payments',
          queue: queue,
          targetCollection: 'bookings',
          targetDocId: widget.booking.bookingId,
          targetField: 'paymentProofUrl',
          extra: {
            'status': 'payment_submitted',
            'transactionId': tid,
          },
        );
      }

      final ds = sl<BookingRemoteDataSource>();
      final updated = await ds.updatePaymentProof(
        bookingId: widget.booking.bookingId,
        paymentProofUrl: proofUrl,
        transactionId: tid,
      );

      if (mounted) {
        AppFeedback.showSuccess(
            context,
            proofUrl.isEmpty
                ? 'Proof submitted! Receipt will sync when you are back online.'
                : 'Proof submitted! Waiting for showroom confirmation.');
        widget.onProofSubmitted?.call(updated);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Failed to submit payment proof: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Text(
                'Submit Payment Proof',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.booking.vehicleName ?? 'Selected Car',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Booking ID: ${widget.booking.bookingId}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Text(
                            'Rs. ${widget.booking.advanceRequired}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Transaction Reference / TID',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tidController,
                      decoration: InputDecoration(
                        hintText: 'Enter JazzCash / Bank TID (e.g. 892019281)',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        prefixIcon: const Icon(Icons.receipt_long_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Proof Screenshot',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ProofScreenshotPicker(
                      selectedFile: _selectedFile,
                      onFileSelected: (f) => setState(() => _selectedFile = f),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock_rounded,
                              size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Proof is uploaded to private storage. The showroom checks it and confirms your booking — there is no fixed waiting time.',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: _isSubmitting ? 'Uploading Proof...' : 'Submit Payment Proof',
                icon: Icons.check_circle_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitProof,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

