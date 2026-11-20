import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../l10n/app_localizations.dart';

import '../../../../core/theme/card_decoration.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../services/contract_pdf_actions.dart';
import 'contract_signing_section.dart';

/// Item 10 (O47): the terms + signatures step — the 10 numbered
/// terms, the three signature states (customer Saved, guarantor
/// Auto-fetched from the saved profile signature or a fresh pad,
/// owner + shop stamp), and Finalize. Finalize stays blocked until
/// all 3 signatures are present; it regenerates the 1-page PDF with
/// the guarantor block + true photo count and marks the agreement
/// fully signed before the wizard advances to sharing.
class AgreementWizardSignatures extends StatefulWidget {
  final BookingEntity booking;
  final int? odometer;
  final String? fuelLevel;
  final int? securityDeposit;
  final Uint8List? customerSignaturePng;
  final Uint8List? ownerSignaturePng;
  final Uint8List? guarantorSignaturePng;
  final String? guarantorSignatureUrl;
  final List<String> damageNotes;
  final int? handoverPhotoCount;
  /// Already-fully-signed (loaded by the wizard parent) — counts
  /// toward Finalize without another Firestore read.
  final bool fullySigned;
  final ValueChanged<Uint8List?> onFinalized;

  const AgreementWizardSignatures({
    super.key,
    required this.booking,
    required this.odometer,
    required this.fuelLevel,
    this.securityDeposit,
    this.customerSignaturePng,
    this.ownerSignaturePng,
    this.guarantorSignaturePng,
    this.guarantorSignatureUrl,
    this.damageNotes = const [],
    this.handoverPhotoCount,
    this.fullySigned = false,
    required this.onFinalized,
  });

  @override
  State<AgreementWizardSignatures> createState() =>
      _AgreementWizardSignaturesState();
}

class _AgreementWizardSignaturesState
    extends State<AgreementWizardSignatures> {
  Uint8List? _guarantorPng;
  String? _guarantorUrl;
  Uint8List? _pdfBytes;
  bool _finalizing = false;

  bool get _canFinalize =>
      widget.customerSignaturePng != null &&
      widget.ownerSignaturePng != null &&
      (_guarantorPng != null || _guarantorUrl != null || widget.fullySigned);

  @override
  void initState() {
    super.initState();
    _guarantorPng = widget.guarantorSignaturePng;
    _guarantorUrl = widget.guarantorSignatureUrl;
    _autoFetchGuarantorImage();
  }

  // The wizard parent resolves the saved guarantor signature
  // asynchronously — pick it up when it arrives after initState.
  @override
  void didUpdateWidget(AgreementWizardSignatures oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_guarantorPng == null && widget.guarantorSignaturePng != null) {
      _guarantorPng = widget.guarantorSignaturePng;
    }
    if (_guarantorUrl == null && widget.guarantorSignatureUrl != null) {
      _guarantorUrl = widget.guarantorSignatureUrl;
      _autoFetchGuarantorImage();
    }
  }

  Future<void> _autoFetchGuarantorImage() async {
    // Auto-fetch: the saved profile signature image, so the PDF
    // can carry the real signature instead of an empty box. A
    // failed fetch leaves the URL state ("Auto-fetched") and the
    // pad as the fallback — never a broken image.
    final url = _guarantorUrl;
    if (_guarantorPng == null && url != null && url.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        if (mounted &&
            response.statusCode == 200 &&
            response.bodyBytes.isNotEmpty) {
          setState(() => _guarantorPng = response.bodyBytes);
        }
      } catch (_) {}
    }
  }

  Future<void> _finalize() async {
    if (!_canFinalize || _finalizing) return;
    setState(() => _finalizing = true);
    Uint8List? newPdf;
    if (_guarantorPng != null) {
      newPdf = await ContractPdfActions.regenerateAgreementPdf(
        booking: widget.booking,
        odometer: widget.odometer,
        fuelLevel: widget.fuelLevel,
        securityDeposit: widget.securityDeposit,
        customerSignaturePng: widget.customerSignaturePng,
        ownerSignaturePng: widget.ownerSignaturePng,
        guarantorSignaturePng: _guarantorPng,
        damageNotes: widget.damageNotes,
        handoverPhotoCount: widget.handoverPhotoCount,
      );
    }
    // Offline-safe: the flag write may fail without connectivity;
    // the wizard still advances on the three signatures actually
    // present in this session, and the PDF bytes travel with it.
    await ContractPdfActions.saveAgreementState(
      bookingId: widget.booking.bookingId,
      fullySigned: true,
      agreementPdfB64: newPdf,
    );
    if (!mounted) return;
    setState(() => _finalizing = false);
    widget.onFinalized(newPdf ?? _pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final terms = [
      l10n.contractTerm1,
      l10n.contractTerm2,
      l10n.contractTerm3,
      l10n.contractTerm4,
      l10n.contractTerm5,
      l10n.contractTerm6,
      l10n.contractTerm7,
      l10n.contractTerm8,
      l10n.contractTerm9,
      l10n.contractTerm10,
    ];
    final guarantorStatus = _guarantorPng != null
        ? l10n.agreementWizardSaved
        : _guarantorUrl != null
            ? l10n.agreementWizardAutoFetched
            : l10n.contractGuarantorPending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < terms.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${i + 1}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      terms[i].replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(l10n.agreementWizardSignatures,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _sigTile(
                context,
                l10n.contractFieldHirer,
                widget.customerSignaturePng,
                widget.customerSignaturePng != null
                    ? l10n.agreementWizardSaved
                    : l10n.contractGuarantorPending,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _sigTile(context, l10n.agreementWizardGuarantor,
                  _guarantorPng, guarantorStatus),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _sigTile(
                context,
                l10n.contractHostSignature,
                widget.ownerSignaturePng,
                widget.ownerSignaturePng != null
                    ? l10n.agreementWizardSaved
                    : l10n.contractGuarantorPending,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.approval_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(l10n.agreementWizardShopStamp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 16),
        ContractSigningSection(
          booking: widget.booking,
          odometer: widget.odometer,
          fuelLevel: widget.fuelLevel,
          securityDeposit: widget.securityDeposit,
          customerSignaturePng: widget.customerSignaturePng,
          ownerSignaturePng: widget.ownerSignaturePng,
          damageNotes: widget.damageNotes,
          onGuarantorSigned: (png) => setState(() => _guarantorPng = png),
          onPdfRegenerated: (bytes) => setState(() => _pdfBytes = bytes),
        ),
        const SizedBox(height: 20),
        if (_canFinalize)
          DebouncedButton(
            text: _finalizing
                ? l10n.contractSigning
                : l10n.agreementWizardFinalize,
            icon: Icons.check_rounded,
            isLoading: _finalizing,
            onPressed: _finalize,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(l10n.agreementWizardFinalize),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(height: 6),
              Text(l10n.agreementWizardFinalizeHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant)),
            ],
          ),
      ],
    );
  }

  Widget _sigTile(
      BuildContext context, String label, Uint8List? png, String status) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (png != null)
            Image.memory(png,
                width: 110, height: 44, fit: BoxFit.contain)
          else
            const Icon(Icons.hourglass_empty_rounded,
                color: Colors.grey, size: 24),
          const SizedBox(height: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          Text(status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: png != null
                      ? colors.primary
                      : colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
