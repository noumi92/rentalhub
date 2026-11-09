import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../handover/data/datasources/handover_local_data_source.dart';
import '../../../handover/data/datasources/pdf_contract_generator.dart';
import '../services/contract_pdf_actions.dart';

/// Audit item 17 (O24): Agreement Signed — the success screen after
/// handover. Green check, Download PDF (save to device), Share via
/// the OS share sheet, Send to Customer via a wa.me deep link with
/// the agreement verification link (manual WhatsApp, same pattern
/// as the dues reminder — no automated send, D2-gated). Continue
/// goes to the Rental Started screen; the contract view stays
/// reachable from both.
class OwnerAgreementSignedView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerAgreementSignedView({
    super.key,
    required this.booking,
    this.onBack,
  });

  @override
  State<OwnerAgreementSignedView> createState() =>
      _OwnerAgreementSignedViewState();
}

class _OwnerAgreementSignedViewState extends State<OwnerAgreementSignedView> {
  Uint8List? _pdfBytes;
  bool _loadingPdf = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final handover = await sl<HandoverLocalDataSource>()
          .getHandover(widget.booking.bookingId);
      final b64 = handover?.agreementPdfB64;
      if (mounted && b64 != null) setState(() => _pdfBytes = base64Decode(b64));
    } catch (_) {}
    if (mounted) setState(() => _loadingPdf = false);
  }

  Future<void> _downloadPdf() async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _pdfBytes;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return;
    }
    await ContractPdfActions.downloadPdf(
      context: context,
      bookingId: widget.booking.bookingId,
      bytes: bytes,
    );
  }

  Future<void> _sharePdf() async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _pdfBytes;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: 'agreement-${widget.booking.bookingId}.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        text: l10n.contractShareText(widget.booking.bookingId),
      ),
    );
  }

  Future<void> _sendToCustomer() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = widget.booking.customerPhone ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final number = digits.startsWith('92')
        ? digits
        : digits.startsWith('0')
            ? '92${digits.substring(1)}'
            : digits;
    if (number.isEmpty) {
      AppFeedback.showError(context, l10n.rentalStartedNoPhone);
      return;
    }
    final url = PdfContractGenerator.verificationUrlFor(widget.booking.bookingId);
    final message = l10n.agreementSignedSendMessage(
      widget.booking.customerName ?? l10n.requestsCustomerFallback,
      url,
    );
    final uri = Uri.parse(
        'https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppFeedback.showError(context, l10n.rentalStartedWhatsappFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.agreementSignedTitle,
              subtitle: '#${widget.booking.bookingId}',
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 56, color: Colors.green.shade700),
                          const SizedBox(height: 12),
                          Text(
                            l10n.agreementSignedBanner,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green.shade800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.agreementSignedSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DebouncedButton(
                      text: l10n.agreementSignedDownloadPdf,
                      icon: Icons.download_rounded,
                      isLoading: _loadingPdf,
                      onPressed: _downloadPdf,
                    ),
                    const SizedBox(height: 12),
                    DebouncedButton(
                      text: l10n.agreementSignedShare,
                      icon: Icons.share_rounded,
                      onPressed: _sharePdf,
                    ),
                    const SizedBox(height: 12),
                    DebouncedButton(
                      text: l10n.agreementSignedSendCustomer,
                      icon: Icons.message_rounded,
                      onPressed: _sendToCustomer,
                    ),
                    const SizedBox(height: 20),
                    DebouncedButton(
                      text: l10n.agreementSignedContinue,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.pushReplacement(
                        RouteNames.ownerRentalStarted
                            .replaceFirst(':id', widget.booking.bookingId),
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
