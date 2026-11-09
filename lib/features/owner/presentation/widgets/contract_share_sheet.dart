import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../services/contract_pdf_actions.dart';

/// Finish build (O24): the in-app share options for the agreement —
/// WhatsApp, Email and Print — as a bottom sheet. Each option hands
/// the PDF file to the app the user picks (WhatsApp / the mail app)
/// via the system share sheet, or to the printer via the existing
/// `printing` package. Nothing is dispatched by the app itself and
/// nothing is claimed to have been sent: the note under the options
/// says so in both languages.
class ContractShareSheet {
  static Future<void> show({
    required BuildContext context,
    required String bookingId,
    required Uint8List? bytes,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final sheetL10n = AppLocalizations.of(sheetContext)!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetL10n.contractShareTitle,
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_rounded),
                title: Text(sheetL10n.contractShareWhatsapp),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ContractPdfActions.sharePdf(
                    context: context,
                    bookingId: bookingId,
                    bytes: bytes,
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_rounded),
                title: Text(sheetL10n.contractShareEmail),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ContractPdfActions.sharePdf(
                    context: context,
                    bookingId: bookingId,
                    bytes: bytes,
                    subject: l10n.contractShareText(bookingId),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.print_rounded),
                title: Text(sheetL10n.contractSharePrint),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ContractPdfActions.printPdf(
                    context: context,
                    bytes: bytes,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                sheetL10n.contractShareNote,
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
