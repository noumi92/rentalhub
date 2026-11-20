import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/theme/card_decoration.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/success_banner.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../handover/data/datasources/pdf_contract_generator.dart';
import '../services/contract_pdf_actions.dart';
import 'contract_share_sheet.dart';
import 'contract_verify_card.dart';

/// Item 10 (O48): the share / download step — "Signed by all 3
/// parties" (only when the three signatures are genuinely present),
/// the file card with TRUE metadata (A4, 1 page, real file size —
/// never the spec's "2 pages"), the QR-verified state, Download /
/// Share on WhatsApp / Print (single copy — a copy count is out of
/// scope) / Copy verification link, and Done to Rental Started.
class AgreementWizardShare extends StatelessWidget {
  final BookingEntity booking;
  final Uint8List? pdfBytes;
  final bool signedByAll;
  final VoidCallback onDone;

  const AgreementWizardShare({
    super.key,
    required this.booking,
    required this.pdfBytes,
    required this.signedByAll,
    required this.onDone,
  });

  /// Honest file-size label: "48 KB", "240 KB", "1.2 MB".
  static String fileSizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bytes = pdfBytes;
    final verificationUrl =
        PdfContractGenerator.verificationUrlFor(booking.bookingId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuccessBanner(
          title: l10n.agreementWizardAgreementReady,
          lines: [
            if (signedByAll) l10n.agreementWizardSignedByAll,
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.picture_as_pdf_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('agreement-${booking.bookingId}.pdf',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        bytes == null
                            ? l10n.contractPdfUnavailable
                            : l10n.agreementWizardFileMeta(
                                fileSizeLabel(bytes.length)),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                    const SizedBox(height: 6),
                    if (bytes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(l10n.agreementWizardQrVerified,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ContractVerifyCard(verificationUrl: verificationUrl),
        const SizedBox(height: 16),
        DebouncedButton(
          text: l10n.agreementSignedDownloadPdf,
          icon: Icons.download_rounded,
          onPressed: () => ContractPdfActions.downloadPdf(
            context: context,
            bookingId: booking.bookingId,
            bytes: bytes,
          ),
        ),
        const SizedBox(height: 12),
        DebouncedButton(
          text: l10n.agreementWizardShareOnWhatsapp,
          icon: Icons.message_rounded,
          onPressed: () =>
              ContractPdfActions.sendVerificationToCustomer(
            context: context,
            booking: booking,
          ),
        ),
        const SizedBox(height: 12),
        DebouncedButton(
          text: l10n.contractSharePrint,
          icon: Icons.print_rounded,
          onPressed: () => ContractPdfActions.printPdf(
            context: context,
            bytes: bytes,
          ),
        ),
        const SizedBox(height: 4),
        Text(l10n.agreementWizardPrintSingleCopy,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        DebouncedButton(
          text: l10n.agreementWizardCopyLink,
          icon: Icons.link_rounded,
          onPressed: () async {
            await Clipboard.setData(
                ClipboardData(text: verificationUrl));
            if (context.mounted) {
              AppFeedback.showSuccess(
                  context, l10n.agreementWizardLinkCopied);
            }
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.share_rounded),
          title: Text(l10n.contractShareTitle),
          trailing:
              const Icon(Icons.chevron_right_rounded),
          onTap: () => ContractShareSheet.show(
            context: context,
            bookingId: booking.bookingId,
            bytes: bytes,
          ),
        ),
        const SizedBox(height: 20),
        DebouncedButton(
          text: l10n.done,
          icon: Icons.check_rounded,
          onPressed: onDone,
        ),
      ],
    );
  }
}
