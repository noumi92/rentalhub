import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';

class ProofScreenshotPicker extends StatelessWidget {
  final File? selectedFile;
  final ValueChanged<File?> onFileSelected;

  const ProofScreenshotPicker({
    super.key,
    required this.selectedFile,
    required this.onFileSelected,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    // §11: a denied picker used to fail silently (no-op). Surface it.
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        onFileSelected(File(picked.path));
      }
    } catch (_) {
      if (context.mounted) {
        AppFeedback.showError(
            context, AppLocalizations.of(context)!.proofPickerPermissionDenied);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (selectedFile != null) {
      return Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          image: DecorationImage(
            image: FileImage(selectedFile!),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => onFileSelected(null),
                child: Container(
                  // §11: 48dp hit area (was ~30dp: 6px padding + 18px
                  // icon); the visual stays the same 18px icon.
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.proofScreenshotReady,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // Theme container + theme icon colour: the const-light
              // primaryContainer with a theme (near-white in dark)
              // icon was unreadable in dark mode.
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_upload_outlined,
                size: 30, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.proofUploadScreenshot,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.proofScreenshotSupport,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(context, ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.photo_library_rounded, size: 16),
                label:  Text(l10n.proofFromGallery),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _pickImage(context, ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label:  Text(l10n.proofCaptureCamera),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

