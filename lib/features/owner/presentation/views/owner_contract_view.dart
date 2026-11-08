import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../handover/data/datasources/handover_local_data_source.dart';
import '../../../handover/data/datasources/pdf_contract_generator.dart';
import '../widgets/contract_paper_sheet.dart';
import 'owner_return_settlement_view.dart';

/// Phase B (E3): the contract screen shows the real generated A4
/// PDF — shareable and printable — plus the verification QR. The
/// old version showed a fake shop name, a fake "Verified Clean"
/// claim, a hardcoded deposit and a share button that only showed a
/// success message.
class OwnerContractView extends StatefulWidget {
  final BookingEntity booking;
  final int odometer;
  final String fuelLevel;
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
    this.odometer = 45200,
    this.fuelLevel = '4/4 (Full)',
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

  @override
  void initState() {
    super.initState();
    _pdfBytes = widget.pdfBytes;
    _customerSig = widget.customerSignaturePng;
    _ownerSig = widget.ownerSignaturePng;
    _verificationUrl = widget.verificationUrl ??
        PdfContractGenerator.verificationUrlFor(widget.booking.bookingId);
    _deposit = widget.securityDeposit;
    if (_pdfBytes == null) _loadStoredHandover();
  }

  Future<void> _loadStoredHandover() async {
    try {
      final handover = await sl<HandoverLocalDataSource>()
          .getHandover(widget.booking.bookingId);
      if (handover == null || !mounted) return;
      setState(() {
        if (handover.agreementPdfB64 != null) {
          _pdfBytes = base64Decode(handover.agreementPdfB64!);
        }
        if (handover.customerSignatureB64 != null) {
          _customerSig = base64Decode(handover.customerSignatureB64!);
        }
        if (handover.ownerSignatureB64 != null) {
          _ownerSig = base64Decode(handover.ownerSignatureB64!);
        }
      });
    } catch (_) {}
  }

  Future<void> _sharePdf() async {
    final bytes = _pdfBytes;
    if (bytes == null) {
      AppFeedback.showError(
          context, 'The agreement PDF is not available yet.');
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
        text: 'Rental agreement #${widget.booking.bookingId}',
      ),
    );
  }

  Future<void> _printPdf() async {
    final bytes = _pdfBytes;
    if (bytes == null) {
      AppFeedback.showError(
          context, 'The agreement PDF is not available yet.');
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Digital Rental Contract',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('Legal Agreement Ref: #${booking.bookingId}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Share PDF',
                  onPressed: _sharePdf,
                ),
                IconButton(
                  icon: const Icon(Icons.print_rounded, color: Colors.white),
                  tooltip: 'Print PDF',
                  onPressed: _printPdf,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    ContractPaperSheet(
                      booking: booking,
                      odometer: widget.odometer,
                      fuelLevel: widget.fuelLevel,
                      securityDeposit: _deposit,
                      customerSignaturePng: _customerSig,
                      ownerSignaturePng: _ownerSig,
                    ),
                    const SizedBox(height: 20),
                    if (_verificationUrl != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            QrImageView(
                              data: _verificationUrl!,
                              size: 96,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Scan to verify this agreement — the '
                                'page shows the booking, the shop and '
                                'the signed PDF.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    DebouncedButton(
                      text: 'Proceed to Return & Settlement',
                      icon: Icons.assignment_return_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerReturnSettlementView(
                              booking: booking,
                              initialOdometer: widget.odometer,
                            ),
                          ),
                        );
                      },
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
