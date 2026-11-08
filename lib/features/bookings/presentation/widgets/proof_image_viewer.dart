import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// §10: the payment-proof screenshot, shown uncropped and tappable to
/// full-screen. The old fixed 220px `BoxFit.cover` crop could cut the
/// TID area off — the evidence the owner must verify — and the image
/// showed blank while loading (only an `errorBuilder` existed).
class ProofImageViewer extends StatelessWidget {
  const ProofImageViewer({
    super.key,
    required this.imageUrl,
    this.height = 220,
  });

  final String imageUrl;
  final double height;

  void _openFullscreen(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) =>
                    loadingProgress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image_rounded)),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: MaterialLocalizations.of(dialogContext).closeButtonTooltip,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // E3: the tap target needs a semantic label (audit batch added
    // this viewer without one — the a11y scan counts 9 detectors).
    return Semantics(
      button: true,
      label: l10n.proofImageOpenFullscreen,
      child: GestureDetector(
        onTap: () => _openFullscreen(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            height: height,
            width: double.infinity,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) =>
                loadingProgress == null
                    ? child
                    : const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ),
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              alignment: Alignment.center,
              // §10: brightness-aware container — the const-light
              // primaryContainer with theme text was ~1.1:1 in dark.
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(l10n.paymentVerificationProofUnavailable),
            ),
          ),
        ),
      ),
    );
  }
}
