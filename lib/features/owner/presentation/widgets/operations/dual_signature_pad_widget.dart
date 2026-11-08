import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:signature/signature.dart';

import '../../../../../core/constants/app_colors.dart';

/// Phase B (E2): two real signature pads. The caller owns the
/// controllers and exports the PNG bytes at handover time — the old
/// version only toggled a boolean and passed a hardcoded SVG string,
/// so no signature ever existed.
class DualSignaturePadWidget extends StatelessWidget {
  final SignatureController customerController;
  final SignatureController ownerController;

  const DualSignaturePadWidget({
    super.key,
    required this.customerController,
    required this.ownerController,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.handoverSignaturesTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _pad(context, l10n,
            title: l10n.handoverCustomerSignature,
            subtitle: l10n.handoverCustomerSignatureHint,
            controller: customerController,
          ),
          const SizedBox(height: 12),
          _pad(context, l10n,
            title: l10n.handoverHostSignature,
            subtitle: l10n.handoverHostSignatureHint,
            controller: ownerController,
          ),
        ],
      ),
    );
  }

  Widget _pad(BuildContext context, AppLocalizations l10n, {
    required String title,
    required String subtitle,
    required SignatureController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                )),
        Text(subtitle,
            style: TextStyle(
                fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Signature(
              controller: controller,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: controller.clear,
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: Text(l10n.handoverClear),
          ),
        ),
      ],
    );
  }
}
