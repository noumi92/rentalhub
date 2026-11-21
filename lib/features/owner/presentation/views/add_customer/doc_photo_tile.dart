import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';

/// One captured-document tile in step 3 (license front/back, utility
/// bill): the photo thumbnail, a Take photo button (which also
/// replaces the photo), and a Remove button once a photo exists so
/// the owner can clear it and capture again. The license tiles show
/// a spinner while OCR runs.
class DocPhotoTile extends StatelessWidget {
  final String label;
  final XFile? file;

  /// Edit mode: the on-file photo (URL) when no fresh capture
  /// exists yet. Null in create mode.
  final String? existingUrl;
  final Key buttonKey;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final Key removeButtonKey;
  final bool scanning;

  const DocPhotoTile({
    super.key,
    required this.label,
    required this.file,
    this.existingUrl,
    required this.buttonKey,
    required this.onPick,
    required this.onRemove,
    required this.removeButtonKey,
    this.scanning = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Local copy so the null check below promotes the type.
    final photo = file;
    final url = existingUrl;
    final hasImage =
        photo != null || (url != null && url.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          height: 120,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
          child: photo == null
              ? (hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Icon(Icons.broken_image_rounded))))
                  : const Center(child: Icon(Icons.image_rounded, size: 40)))
              : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(photo.path), width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded)))),
        ),
        const SizedBox(height: 6),
        // While license OCR runs the button shows the spinner +
        // "Scanning…" text and is disabled — the _scanning flags
        // existed but were never shown in build. The two buttons
        // stack vertically: side by side they overflow the
        // half-width license tile at 360px.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(key: buttonKey, onPressed: scanning ? null : onPick, icon: scanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt_rounded), label: Text(scanning ? l10n.kycScanning : l10n.kycTakePhoto)),
        ),
        if (hasImage)
          Align(
            alignment: Alignment.centerLeft,
            // DS-17: 48dp hit area, like the CNIC remove (48x48
            // IconButton) — a bare TextButton has no such guarantee.
            child: TextButton(key: removeButtonKey, style: TextButton.styleFrom(minimumSize: const Size(0, 48)), onPressed: scanning ? null : onRemove, child: Text(l10n.kycWizardRemoveImage)),
          ),
      ],
    );
  }
}
