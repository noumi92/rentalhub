import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/media_picker_helper.dart';
import '../../../../../l10n/app_localizations.dart';

/// One hand of the step-2 fingerprint capture: a PHOTO of the
/// 4 fingers (index/middle/ring/little) taken with the REAR camera.
///
/// This is a photo, never a scan: there is no fingerprint SDK in
/// the app (BioPass turned out not to be free), so no minutiae are
/// extracted and no matching happens anywhere. The photo is saved
/// and an admin reviews it manually, like the face photo. The
/// gallery is never offered — KYC media is camera-only.
class FingerCaptureSection extends StatelessWidget {
  final String title;
  final XFile? photo;

  /// Edit mode: the on-file photo (URL) when no fresh capture
  /// exists yet. Null in create mode.
  final String? existingUrl;
  final ValueChanged<XFile> onCaptured;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Key scanButtonKey;
  final Key retakeButtonKey;
  final Key removeButtonKey;

  const FingerCaptureSection({
    super.key,
    required this.title,
    required this.photo,
    this.existingUrl,
    required this.onCaptured,
    required this.onRemove,
    required this.onChanged,
    required this.scanButtonKey,
    required this.retakeButtonKey,
    required this.removeButtonKey,
  });

  Future<void> _takePhoto(BuildContext context) async {
    // KYC no-gallery rule: the rear camera directly, like
    // CNIC/license — never the gallery sheet.
    await MediaPickerHelper.showMediaSourceSheet(
      context: context,
      cameraOnly: true,
      onImageSelected: (file) {
        if (file == null) return;
        onCaptured(file);
        onChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final url = existingUrl;
    final hasExisting = url != null && url.isNotEmpty;
    final captured = photo != null || hasExisting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: captured
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photo != null
                      ? Image.file(
                          File(photo!.path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image_rounded),
                        )
                      : Image.network(
                          url!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image_rounded),
                        ),
                )
              : const Center(child: Icon(Icons.fingerprint_rounded, size: 48)),
        ),
        const SizedBox(height: 8),
        Text(
          captured ? l10n.kycWizardFingerCaptured : l10n.kycWizardFingerHint,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Wrap, not Row: Take photo + Retake + Remove do not fit
        // on one line at 360px.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: scanButtonKey,
              onPressed: () => _takePhoto(context),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(l10n.kycTakePhoto),
            ),
            if (captured) ...[
              // DS-17: 48dp hit area, like the CNIC remove (48x48
              // IconButton) — bare TextButtons have no such guarantee.
              TextButton(
                key: retakeButtonKey,
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () => _takePhoto(context),
                child: Text(l10n.kycWizardRetake),
              ),
              TextButton(
                key: removeButtonKey,
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onRemove,
                child: Text(l10n.kycWizardRemoveImage),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
