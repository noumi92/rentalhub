import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../handover/data/datasources/pdf_contract_generator.dart';
import '../services/contract_pdf_actions.dart';

/// Finish build (O20): the explicit-agreement section on the contract
/// view — an "I agree to the terms" checkbox, a guarantor / witness
/// signature pad, and a "Sign Agreement" button.
///
/// The checkbox is an additional explicit agreement, persisted on
/// `agreements/{bookingId}` (merge — the handover-written PDF URL,
/// hash and status are untouched); signing still happens at handover.
/// The button enables only once the guarantor signature is captured;
/// signing stores the guarantor PNG on the agreement record, marks
/// the agreement fully signed, and regenerates the A4 PDF with the
/// third signature block (when the handover odometer/fuel are known —
/// without them the PDF cannot be regenerated honestly, so the stored
/// PDF is kept and only the signature + flags are saved). The parent
/// view renders the captured signature on the paper sheet and swaps
/// in the regenerated PDF for share/print.
class ContractSigningSection extends StatefulWidget {
  final BookingEntity booking;
  final int? odometer;
  final String? fuelLevel;
  final int? securityDeposit;
  final Uint8List? customerSignaturePng;
  final Uint8List? ownerSignaturePng;
  final List<String> damageNotes;
  final ValueChanged<Uint8List> onGuarantorSigned;
  final ValueChanged<Uint8List> onPdfRegenerated;

  const ContractSigningSection({
    super.key,
    required this.booking,
    this.odometer,
    this.fuelLevel,
    this.securityDeposit,
    this.customerSignaturePng,
    this.ownerSignaturePng,
    this.damageNotes = const [],
    required this.onGuarantorSigned,
    required this.onPdfRegenerated,
  });

  @override
  State<ContractSigningSection> createState() =>
      _ContractSigningSectionState();
}

class _ContractSigningSectionState extends State<ContractSigningSection> {
  final _guarantorSig = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white);
  bool _wasEmpty = true;
  bool _agreed = false;
  bool _fullySigned = false;
  bool _loadingState = true;
  bool _signing = false;

  @override
  void initState() {
    super.initState();
    _guarantorSig.addListener(() {
      if (!mounted) return;
      final empty = _guarantorSig.isEmpty;
      if (empty != _wasEmpty) {
        _wasEmpty = empty;
        setState(() {});
      }
    });
    _loadAgreementState();
  }

  Future<void> _loadAgreementState() async {
    final state = await ContractPdfActions.loadAgreementState(
        bookingId: widget.booking.bookingId);
    if (!mounted) return;
    setState(() {
      _agreed = state.agreedToTerms;
      _fullySigned = state.fullySigned;
      _loadingState = false;
    });
    if (state.guarantorSignaturePng != null) {
      widget.onGuarantorSigned(state.guarantorSignaturePng!);
    }
  }

  @override
  void dispose() {
    _guarantorSig.dispose();
    super.dispose();
  }

  Future<void> _onAgreeChanged(bool? value) async {
    if (value == null || _signing) return;
    final previous = _agreed;
    setState(() => _agreed = value);
    final ok = await ContractPdfActions.saveAgreementState(
      bookingId: widget.booking.bookingId,
      agreedToTerms: value,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _agreed = previous);
      AppFeedback.showError(
          context, AppLocalizations.of(context)!.contractAgreeSaveFailed);
    }
  }

  Future<void> _signAgreement() async {
    if (_guarantorSig.isEmpty || _signing || _fullySigned) return;
    setState(() => _signing = true);
    try {
      final png = await _guarantorSig.toPngBytes();
      if (png == null) {
        if (mounted) {
          AppFeedback.showError(
              context, AppLocalizations.of(context)!.contractSignFailed);
        }
        return;
      }
      final booking = widget.booking;
      Uint8List? newPdf;
      if (widget.odometer != null && widget.fuelLevel != null) {
        newPdf = await PdfContractGenerator.generateA4Agreement(
          agreementId: booking.bookingId,
          shopName: booking.shopName ?? 'RentalHub',
          customerName: booking.customerName ?? '',
          cnicNumber: booking.customerCnic ?? '',
          customerPhone: booking.customerPhone ?? '',
          vehicleDetails: booking.vehicleName ?? '',
          packageType: booking.packageType,
          isWithDriver: booking.isWithDriver,
          pickupTime: booking.pickupTime,
          returnTime: booking.returnTime,
          totalAmount: booking.totalAmount,
          advancePaid: booking.advancePaid,
          securityDeposit: widget.securityDeposit ?? 0,
          initialOdometer: widget.odometer!,
          fuelLevel: widget.fuelLevel!,
          damageNotes: widget.damageNotes,
          customerSignaturePng: widget.customerSignaturePng,
          ownerSignaturePng: widget.ownerSignaturePng,
          guarantorSignaturePng: png,
          guarantorName: booking.guarantorName,
          vehiclePlate: booking.vehiclePlate,
        );
      }
      final ok = await ContractPdfActions.saveAgreementState(
        bookingId: booking.bookingId,
        agreedToTerms: _agreed,
        guarantorSignaturePng: png,
        fullySigned: true,
        agreementPdfB64: newPdf,
      );
      if (!mounted) return;
      if (!ok) {
        AppFeedback.showError(
            context, AppLocalizations.of(context)!.contractSignFailed);
        return;
      }
      widget.onGuarantorSigned(png);
      if (newPdf != null) widget.onPdfRegenerated(newPdf);
      setState(() => _fullySigned = true);
      AppFeedback.showSuccess(
          context, AppLocalizations.of(context)!.contractAgreementSigned);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
            context, AppLocalizations.of(context)!.contractSignFailed);
      }
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.contractGuarantorTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          // The tile paints its ink on the nearest Material ancestor;
          // the decorated Container above would hide it, so the tile
          // gets its own transparent Material (debug assertion).
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.contractAgreeTerms,
                  style: Theme.of(context).textTheme.bodyMedium),
              value: _agreed,
              onChanged: _loadingState ? null : _onAgreeChanged,
            ),
          ),
          const SizedBox(height: 8),
          if (_fullySigned) ...[
            Row(
              children: [
                Icon(Icons.verified_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.contractAgreementSigned,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              l10n.contractGuarantorHint,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _guarantorSig,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _guarantorSig.clear,
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: Text(l10n.handoverClear),
              ),
            ),
            const SizedBox(height: 4),
            if (_guarantorSig.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.draw_rounded, size: 18),
                  label: Text(l10n.contractSignAgreement),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              DebouncedButton(
                text:
                    _signing ? l10n.contractSigning : l10n.contractSignAgreement,
                icon: Icons.draw_rounded,
                isLoading: _signing,
                onPressed: _signAgreement,
              ),
          ],
        ],
      ),
    );
  }
}
