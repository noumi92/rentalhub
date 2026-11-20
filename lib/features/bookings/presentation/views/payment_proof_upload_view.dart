import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../services/payment_proof_upload_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/proof_amount_card.dart';
import '../widgets/proof_screenshot_picker.dart';
import '../../../../l10n/app_localizations.dart';

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
  // §11: inline validation errors — the empty TID / missing
  // screenshot used to surface only as a snackbar, with the
  // offending field unmarked.
  String? _tidError;
  String? _screenshotError;

  @override
  void dispose() {
    _tidController.dispose();
    super.dispose();
  }

  /// PW-6: the shop's WhatsApp link — the number is the booking's
  /// real shop phone; no link renders when the booking carries none.
  Future<void> _messageShop() async {
    final phone = widget.booking.shopPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = whatsappUri(phone: phone, message: AppLocalizations.of(context)!.proofBookingId(widget.booking.bookingId));
    if (uri == null || !await launchUrl(uri)) {
      if (mounted) AppFeedback.showError(context, AppLocalizations.of(context)!.couldNotOpenWhatsapp);
    }
  }

  Future<void> _submitProof() async {
    final l10n = AppLocalizations.of(context)!;
    final tid = _tidController.text.trim();
    // §11: mark the offending field inline instead of snackbar-only.
    setState(() {
      _tidError = tid.isEmpty ? l10n.proofEnterTid : null;
      _screenshotError =
          _selectedFile == null ? l10n.proofAttachFirst : null;
    });
    if (tid.isEmpty || _selectedFile == null) return;

    setState(() => _isSubmitting = true);
    try {
      // Item 8: the same upload path as the vehicle / handover
      // photo uploads (PaymentProofUploadService): uploadOrQueue
      // with folder 'payments', targeting
      // bookings/{id}.paymentProofUrl. It never returns a fake URL.
      final cpanel = sl<CPanelStorageClient>();
      final queue =
          sl.isRegistered<OfflineSyncQueue>() ? sl<OfflineSyncQueue>() : null;
      final result = await PaymentProofUploadService.uploadProof(
        client: cpanel,
        file: _selectedFile!,
        customerId: widget.booking.customerId,
        bookingId: widget.booking.bookingId,
        transactionId: tid,
        queue: queue,
      );

      // GUARD (non-negotiable): no URL, no `payment_submitted`, no
      // success message. updatePaymentProof stamps status +
      // proofSubmittedAt unconditionally, so it only runs on a real
      // URL — the old code called it with '' after a failed upload
      // and showed "Proof submitted!" anyway.
      switch (result.status) {
        case PaymentProofUploadStatus.queued:
          // Upload failed but the receipt is queued: the drain
          // files the real URL + payment_submitted when online.
          // A pending state, not a submission.
          if (mounted) AppFeedback.showInfo(context, l10n.proofUploadQueued);
          return;
        case PaymentProofUploadStatus.failed:
          if (mounted) {
            AppFeedback.showError(context, l10n.proofSubmitFailedGeneric);
          }
          return;
        case PaymentProofUploadStatus.uploaded:
          break;
      }

      final ds = sl<BookingRemoteDataSource>();
      final updated = await ds.updatePaymentProof(
        bookingId: widget.booking.bookingId,
        paymentProofUrl: result.proofUrl!,
        transactionId: tid,
      );

      if (mounted) {
        AppFeedback.showSuccess(context, l10n.proofSubmitted);
        widget.onProofSubmitted?.call(updated);
      }
    } catch (e) {
      debugPrint('Payment proof submit failed: $e');
      if (mounted) {
        AppFeedback.showError(context, l10n.proofSubmitFailedGeneric);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: l10n.proofSubmit, onBack: widget.onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProofAmountCard(booking: widget.booking),
                    // PW-3: copy the advance amount — the payer never types it. (Deep link to JazzCash/Easypaisa: NOT added — neither app publishes a documented payment deep-link scheme, so an invented `jazzcash://` URI could silently fail or open the wrong screen; copy + paste is the reliable path.)
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text('${l10n.summaryAdvancePayable}: ${l10n.amountRs(formatRs(widget.booking.advanceRequired))}', style: Theme.of(context).textTheme.bodyMedium)),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          tooltip: l10n.proofCopyAdvance,
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: '${widget.booking.advanceRequired}'));
                            if (context.mounted) AppFeedback.showSuccess(context, l10n.proofAdvanceCopied);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.proofTidLabel,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tidController,
                      onChanged: (_) {
                        if (_tidError != null) {
                          setState(() => _tidError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: l10n.proofTidHint,
                        errorText: _tidError,
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        prefixIcon: const Icon(Icons.receipt_long_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.proofScreenshot,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    ProofScreenshotPicker(
                      selectedFile: _selectedFile,
                      onFileSelected: (f) => setState(() {
                        _selectedFile = f;
                        if (f != null) _screenshotError = null;
                      }),
                    ),
                    if (_screenshotError != null) ...[
                      const SizedBox(height: 6),
                      Text(_screenshotError!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        // §11: brightness-aware container — the const-light primaryContainer with theme text was unreadable in dark mode.
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock_rounded, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text(l10n.proofPrivateNote, style: Theme.of(context).textTheme.labelSmall)),
                        ],
                      ),
                    ),
                    // PW-6: the reworded note names the real next step (in-app notification on confirmation); the WhatsApp button below is the shop's real link.
                    if (widget.booking.shopPhone != null && widget.booking.shopPhone!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(onPressed: _messageShop, icon: const Icon(Icons.chat_rounded, size: 18), label: Text(l10n.proofMessageShop)),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: Offset(0, -3))],
              ),
              child: DebouncedButton(
                text: _isSubmitting ? l10n.proofUploading : l10n.proofSubmit,
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
