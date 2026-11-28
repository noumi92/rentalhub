import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../../../handover/data/datasources/handover_local_data_source.dart';
import '../services/contract_pdf_actions.dart';
import '../widgets/agreement_wizard_preview.dart';
import '../widgets/agreement_wizard_share.dart';
import '../widgets/agreement_wizard_signatures.dart';

/// Item 10 (O46–O48): the agreement wizard after handover —
/// 0 Preview (Generated badge, paper sheet, guarantor details,
/// true photo count), 1 Terms & signatures (Finalize blocked until
/// all 3 signatures exist), 2 Share / download (true file metadata:
/// A4, 1 page, real size). The agreement number stays the RH-...
/// bookingId everywhere; the older ownerContract route stays
/// reachable (the old ownerAgreementSigned screen is superseded by
/// this wizard's step 2 — its route was removed, its view file stays
/// in the tree unrouted for the handover tests).
class OwnerAgreementWizardView extends StatefulWidget {
  final BookingEntity booking;
  final int initialStep;
  final VoidCallback? onBack;

  /// Seed overrides (tests / callers that already hold the data) —
  /// anything null is loaded from the stored handover instead.
  final Uint8List? pdfBytes;
  final Uint8List? customerSignaturePng;
  final Uint8List? ownerSignaturePng;
  final Uint8List? guarantorSignaturePng;
  final int? handoverPhotoCount;
  final int? odometer;
  final String? fuelLevel;
  final int? securityDeposit;

  const OwnerAgreementWizardView({
    super.key,
    required this.booking,
    this.initialStep = 0,
    this.onBack,
    this.pdfBytes,
    this.customerSignaturePng,
    this.ownerSignaturePng,
    this.guarantorSignaturePng,
    this.handoverPhotoCount,
    this.odometer,
    this.fuelLevel,
    this.securityDeposit,
  });

  @override
  State<OwnerAgreementWizardView> createState() =>
      _OwnerAgreementWizardViewState();
}

class _OwnerAgreementWizardViewState
    extends State<OwnerAgreementWizardView> {
  int _step = 0;
  Uint8List? _pdfBytes;
  Uint8List? _customerSig;
  Uint8List? _ownerSig;
  Uint8List? _guarantorSigPng;
  String? _guarantorSigUrl;
  String? _guarantorName;
  String? _licenseNumber;
  int? _photoCount;
  int? _odometer;
  String? _fuelLevel;
  List<String> _damageNotes = const [];
  bool _fullySigned = false;
  bool _loadingStored = false;

  bool get _hasGuarantor =>
      (widget.booking.guarantorName?.trim().isNotEmpty ?? false) ||
      (widget.booking.guarantorCnic?.trim().isNotEmpty ?? false) ||
      (_guarantorName?.trim().isNotEmpty ?? false);

  bool get _signedByAll =>
      _fullySigned ||
      (_customerSig != null &&
          _ownerSig != null &&
          (!_hasGuarantor || _guarantorSigPng != null || _guarantorSigUrl != null));

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, 2);
    _pdfBytes = widget.pdfBytes;
    _customerSig = widget.customerSignaturePng;
    _ownerSig = widget.ownerSignaturePng;
    _guarantorSigPng = widget.guarantorSignaturePng;
    _photoCount = widget.handoverPhotoCount;
    _odometer = widget.odometer;
    _fuelLevel = widget.fuelLevel;
    if (_pdfBytes == null) {
      _loadingStored = true;
      _loadStoredHandover();
    }
    ContractPdfActions.resolveGuarantorSignature(
      customerId: widget.booking.customerId,
      bookingGuarantorName: widget.booking.guarantorName,
    ).then((resolved) {
      if (mounted) {
        setState(() {
          _guarantorSigUrl = resolved.signatureUrl;
          _guarantorSigPng ??= resolved.signaturePng;
          _guarantorName = resolved.name;
        });
      }
    });
    ContractPdfActions.resolveCustomerLicenseNumber(customerId: widget.booking.customerId).then((license) {
      if (mounted && license != null) setState(() => _licenseNumber = license);
    });
    ContractPdfActions.loadAgreementState(bookingId: widget.booking.bookingId).then((state) {
      if (mounted) setState(() { _fullySigned = state.fullySigned; _guarantorSigPng ??= state.guarantorSignaturePng; });
    });
  }

  Future<void> _loadStoredHandover() async {
    try {
      final handover = await sl<HandoverLocalDataSource>()
          .getHandover(widget.booking.bookingId);
      if (!mounted) return;
      setState(() {
        if (handover != null) {
          _odometer ??= handover.initialOdometer;
          _fuelLevel ??= handover.fuelLevel;
          _damageNotes = handover.damageNotes;
          _photoCount ??= handover.photoCount;
          if (handover.agreementPdfB64 != null) {
            _pdfBytes ??= base64Decode(handover.agreementPdfB64!);
          }
          if (handover.customerSignatureB64 != null) {
            _customerSig ??= base64Decode(handover.customerSignatureB64!);
          }
          if (handover.ownerSignatureB64 != null) {
            _ownerSig ??= base64Decode(handover.ownerSignatureB64!);
          }
        }
        _loadingStored = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStored = false);
    }
  }

  void _onBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      goToAllOwnerBookings(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;
    final titles = [
      l10n.agreementWizardTitle,
      l10n.agreementWizardTermsSignatures,
      l10n.agreementWizardShareTitle,
    ];
    final subtitles = [
      '#${booking.bookingId}',
      l10n.agreementWizardTermsSubtitle,
      '#${booking.bookingId}',
    ];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: titles[_step],
              subtitle: subtitles[_step],
              onBack: _onBack,
            ),
            Expanded(
              child: _loadingStored
                  ? AppLoadingState(message: titles[_step])
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: _step == 0
                          ? AgreementWizardPreview(
                              booking: booking,
                              pdfBytes: _pdfBytes,
                              odometer: _odometer,
                              fuelLevel: _fuelLevel,
                              securityDeposit: widget.securityDeposit,
                              customerSignaturePng: _customerSig,
                              ownerSignaturePng: _ownerSig,
                              guarantorSignatureUrl: _guarantorSigUrl,
                              guarantorSignaturePng: _guarantorSigPng,
                              guarantorName: _guarantorName,
                              licenseNumber: _licenseNumber,
                              handoverPhotoCount: _photoCount,
                              onNext: () => setState(() => _step = 1),
                            )
                          : _step == 1
                              ? AgreementWizardSignatures(
                                  booking: booking,
                                  odometer: _odometer,
                                  fuelLevel: _fuelLevel,
                                  securityDeposit: widget.securityDeposit,
                                  customerSignaturePng: _customerSig,
                                  ownerSignaturePng: _ownerSig,
                                  guarantorSignaturePng: _guarantorSigPng,
                                  guarantorSignatureUrl: _guarantorSigUrl,
                                  damageNotes: _damageNotes,
                                  handoverPhotoCount: _photoCount,
                                  fullySigned: _fullySigned,
                                  onFinalized: (bytes) => setState(() {
                                    if (bytes != null) _pdfBytes = bytes;
                                    _fullySigned = true;
                                    _step = 2;
                                  }),
                                )
                              : AgreementWizardShare(
                                  booking: booking,
                                  pdfBytes: _pdfBytes,
                                  signedByAll: _signedByAll,
                                  onViewAgreement: () =>
                                      setState(() => _step = 0),
                                  onDone: () => goToAllOwnerBookings(context),
                                ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
