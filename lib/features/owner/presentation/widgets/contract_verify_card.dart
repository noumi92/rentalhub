import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// The scan-to-verify QR card on the contract screen. Extracted so
/// [OwnerContractView] stays under the 250-line cap.
class ContractVerifyCard extends StatelessWidget {
  const ContractVerifyCard({super.key, required this.verificationUrl});

  final String verificationUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Row(
        children: [
          QrImageView(
            data: verificationUrl,
            size: 96,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.contractScanVerify,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // Item 10 (O48): copy the verification link — the same
          // URL the QR encodes.
          IconButton(
            tooltip: l10n.agreementWizardCopyLink,
            icon: const Icon(Icons.link_rounded),
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: verificationUrl));
              if (context.mounted) {
                AppFeedback.showSuccess(
                    context, l10n.agreementWizardLinkCopied);
              }
            },
          ),
        ],
      ),
    );
  }
}
