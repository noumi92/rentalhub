import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/success_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../../../handover/data/datasources/handover_local_data_source.dart';
import '../services/contract_pdf_actions.dart';

/// Audit item 17 (O24): Agreement Signed — Download PDF and View
/// Agreement only (no public verification links or share actions).
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
  // OW-m26: a failed PDF load used to fail silently (empty catch) and
  // the Download button only failed later with the generic
  // "unavailable" message. The failure is now surfaced with a retry.
  bool _pdfFailed = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    if (mounted) setState(() => _pdfFailed = false);
    try {
      final handover = await sl<HandoverLocalDataSource>()
          .getHandover(widget.booking.bookingId);
      final b64 = handover?.agreementPdfB64;
      if (mounted && b64 != null) setState(() => _pdfBytes = base64Decode(b64));
    } catch (_) {
      if (mounted) setState(() => _pdfFailed = true);
    }
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
              onBack: widget.onBack ??
                  () => context.canPop()
                      ? context.pop()
                      : goToAllOwnerBookings(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // OW-M5: the shared brightness-aware banner (was a
                    // fixed-light green slab with a theme subtitle,
                    // invisible in dark mode).
                    SuccessBanner(
                      title: l10n.agreementSignedBanner,
                      lines: [l10n.agreementSignedSubtitle],
                    ),
                    // OW-m26: the PDF never loaded — say so with a
                    // retry instead of letting Download fail later.
                    if (_pdfFailed) ...[
                      const SizedBox(height: 12),
                      AppErrorState(
                        message: l10n.contractPdfUnavailable,
                        onRetry: _loadPdf,
                      ),
                    ],
                    const SizedBox(height: 20),
                    DebouncedButton(
                      text: l10n.agreementSignedDownloadPdf,
                      icon: Icons.download_rounded,
                      isLoading: _loadingPdf,
                      onPressed: _downloadPdf,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        RouteNames.ownerAgreementWizard
                            .replaceFirst(':id', widget.booking.bookingId),
                      ),
                      icon: const Icon(Icons.description_rounded),
                      label: Text(l10n.rentalStartedViewAgreement),
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
