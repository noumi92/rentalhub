import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../../core/theme/card_decoration.dart';
import '../../../../../l10n/app_localizations.dart';

/// Item 9 (O30): one signature slot on the agreement step — the
/// saved signature shown "on file" when it exists and is chosen,
/// otherwise the fresh pad. Extracted so the step stays under the
/// 250-line cap.
class HandoverWizardSignatureBlock extends StatelessWidget {
  final String title;
  final String? savedUrl;
  final Uint8List? savedPng;
  final bool useSaved;
  final ValueChanged<bool> onToggleUseSaved;
  final SignatureController controller;

  const HandoverWizardSignatureBlock({
    super.key,
    required this.title,
    required this.savedUrl,
    required this.savedPng,
    required this.useSaved,
    required this.onToggleUseSaved,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasSaved = savedUrl != null && savedUrl!.isNotEmpty ||
        savedPng != null;
    final showSaved = hasSaved && useSaved;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (showSaved) ...[
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: savedPng != null
                  ? Image.memory(savedPng!, fit: BoxFit.contain)
                  : Image.network(savedUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_rounded))),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(l10n.handoverWizardSignatureOnFile,
                        style: Theme.of(context).textTheme.bodyMedium)),
                TextButton(
                  onPressed: () => onToggleUseSaved(false),
                  child: Text(l10n.handoverWizardSignFresh),
                ),
              ],
            ),
          ] else ...[
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
            if (hasSaved)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onToggleUseSaved(true),
                  child: Text(l10n.handoverWizardUseSaved),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
