import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../handover/data/datasources/handover_local_data_source.dart';
import '../../../handover/data/datasources/pdf_contract_generator.dart';
import '../widgets/contract_paper_sheet.dart';
import '../widgets/contract_verify_card.dart';

/// Phase B (E3): the contract screen shows the real generated A4
/// PDF — shareable and printable — plus the verification QR. The
/// old version showed a fake shop name, a fake "Verified Clean"
/// claim, a hardcoded deposit and a share button that only showed a
/// success message.
class OwnerContractView extends StatefulWidget {
  final BookingEntity booking;

  /// Handover values (normally null — the route carries none, so the
  /// view loads them from the stored handover); null renders as "—".
  final int? odometer;
  final String? fuelLevel;
  final VoidCallback? onBack;

  /// The PDF bytes from the handover flow. When null, the view
  /// looks the stored handover up by booking id instead.
  final Uint8List? pdfBytes;
  final String? verificationUrl;
  final Uint8List? customerSignaturePng;
  final Uint8List? ownerSignaturePng;
  final int? securityDeposit;

  const OwnerContractView({
    super.key,
    required this.booking,
    this.odometer,
    this.fuelLevel,
    this.onBack,
    this.pdfBytes,
    this.verificationUrl,
    this.customerSignaturePng,
    this.ownerSignaturePng,
    this.securityDeposit,
  });

  @override
  State<OwnerContractView> createState() => _OwnerContractViewState();
}

class _OwnerContractViewState extends State<OwnerContractView> {
  Uint8List? _pdfBytes;
  Uint8List? _customerSig;
  Uint8List? _ownerSig;
  String? _verificationUrl;
  int? _deposit;
  // C11 follow-up: odometer/fuel used to default to 45200 /
  // '4/4 (Full)'. They now come from the stored handover.
  int? _storedOdometer;
  String? _storedFuelLevel;
  // §15: while the stored handover is still loading we cannot know
  // whether an agreement exists — the paper must not render on
  // fallbacks in the meantime.
  bool _loadingStored = false;

  /// True once a PDF or at least one stored signature exists.
  bool get _hasAgreement =>
      _pdfBytes != null || _customerSig != null || _ownerSig != null;

  @override
  void initState() {
    super.initState();
    _pdfBytes = widget.pdfBytes;
    _customerSig = widget.customerSignaturePng;
    _ownerSig = widget.ownerSignaturePng;
    _verificationUrl = widget.verificationUrl ??
        PdfContractGenerator.verificationUrlFor(widget.booking.bookingId);
    _deposit = widget.securityDeposit;
    if (_pdfBytes == null) {
      _loadingStored = true;
      _loadStoredHandover();
    }
  }

  Future<void> _loadStoredHandover() async {
    try {
      final handover = await sl<HandoverLocalDataSource>()
          .getHandover(widget.booking.bookingId);
      if (!mounted) return;
      setState(() {
        if (handover != null) {
          _storedOdometer = handover.initialOdometer; _storedFuelLevel = handover.fuelLevel;
          if (handover.agreementPdfB64 != null) {
            _pdfBytes = base64Decode(handover.agreementPdfB64!);
          }
          if (handover.customerSignatureB64 != null) {
            _customerSig = base64Decode(handover.customerSignatureB64!);
          }
          if (handover.ownerSignatureB64 != null) {
            _ownerSig = base64Decode(handover.ownerSignatureB64!);
          }
        }
        _loadingStored = false;
      });
    } catch (_) {
      // C4: a failed lookup is not silent any more — the loading
      // state ends and the honest "agreement not available" state
      // renders instead of spinning forever.
      if (mounted) setState(() => _loadingStored = false);
    }
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

  Future<void> _printPdf() async {
  final l10n = AppLocalizations.of(context)!;
    final bytes = _pdfBytes;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.contractTitle,
              subtitle: l10n.contractLegalRef(booking.bookingId),
              onBack: widget.onBack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: l10n.contractSharePdf,
                  onPressed: _sharePdf,
                ),
                IconButton(
                  icon: const Icon(Icons.print_rounded, color: Colors.white),
                  tooltip: l10n.contractPrintPdf,
                  onPressed: _printPdf,
                ),
              ],
            ),
            Expanded(
              child: _loadingStored
                  ? AppLoadingState(message: l10n.contractTitle)
                  : !_hasAgreement
                      // §15: honest missing state — no PDF and no
                      // stored handover means no paper on fallbacks.
                      ? AppEmptyState(
                          title: l10n.contractNotAvailable,
                          message: l10n.contractPdfUnavailable,
                          icon: Icons.description_outlined,
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            children: [
                              ContractPaperSheet(
                                booking: booking,
                                odometer: widget.odometer ?? _storedOdometer,
                                fuelLevel: widget.fuelLevel ?? _storedFuelLevel,
                                securityDeposit: _deposit,
                                customerSignaturePng: _customerSig,
                                ownerSignaturePng: _ownerSig,
                              ),
                              const SizedBox(height: 20),
                              if (_verificationUrl != null) ...[
                                ContractVerifyCard(
                                    verificationUrl: _verificationUrl!),
                                const SizedBox(height: 20),
                              ],
                              // §15: Proceed only once handed over
                              // ('active'); C11: go_router, not push.
                              if (booking.status == 'active')
                                DebouncedButton(
                                  text: l10n.contractProceedReturn,
                                  icon: Icons.assignment_return_rounded,
                                  onPressed: () => context.push(
                                    RouteNames.ownerReturn.replaceFirst(
                                        ':id', booking.bookingId),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                        Icons.assignment_return_rounded,
                                        size: 18),
                                    label: Text(l10n.contractProceedReturn),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 54),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    ),
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
