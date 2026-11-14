import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// The fleet photos on a shop application: thumbnails that open a
/// full-screen view on tap. A photo that cannot load shows a broken
/// image icon instead of crashing the sheet.
class ShopFleetPhotos extends StatelessWidget {
  const ShopFleetPhotos({super.key, required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: photoUrls
          .map((url) => Semantics(
              button: true,
              label: l10n.admin2_fleetPhotoTooltip,
              // E3: the thumbnail is a labelled button for screen
              // readers; the tap behaviour is unchanged.
              child: GestureDetector(
                onTap: () => _zoom(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          width: 72,
                          height: 72,
                          child: Icon(Icons.broken_image_rounded))),
                ),
              )))
          .toList(),
    );
  }

  /// AD-m17: the full-screen dialog reuses the KYC document tile's
  /// zoom pattern (InteractiveViewer + BoxFit.contain + insetPadding)
  /// with a loading indicator while the full image downloads and an
  /// explicit close button — the old bare Dialog had none of the
  /// three, and an unconstrained large image could overflow it.
  void _zoom(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(AppLocalizations.of(context)!
                        .admin2_fleetPhotoFailed)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
