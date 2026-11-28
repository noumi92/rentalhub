import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/card_decoration.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/success_banner.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../services/contract_pdf_actions.dart';

/// Item 10 (O48): the agreement ready step — Download PDF and
/// View Agreement only (no public verification links or share sheets),
/// plus Done to return to bookings.
class AgreementWizardShare extends StatelessWidget {
  final BookingEntity booking;
  final Uint8List? pdfBytes;
  final bool signedByAll;
  final VoidCallback? onViewAgreement;
  final VoidCallback onDone;

  const AgreementWizardShare({
    super.key,
    required this.booking,
    required this.pdfBytes,
    required this.signedByAll,
    this.onViewAgreement,
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
                  ],
                ),
              ),
            ],
          ),
        ),
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
        OutlinedButton.icon(
          onPressed: onViewAgreement ??
              () => context.push(
                    RouteNames.ownerContract
                        .replaceFirst(':id', booking.bookingId),
                  ),
          icon: const Icon(Icons.description_rounded),
          label: Text(l10n.rentalStartedViewAgreement),
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
