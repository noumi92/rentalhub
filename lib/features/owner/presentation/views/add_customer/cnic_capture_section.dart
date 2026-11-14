import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';
import 'kyc_draft.dart';

/// The CNIC capture area at the top of step 1: Scan buttons (rear
/// camera), gallery buttons (the parent OCR-checks gallery picks —
/// a gallery photo that yields nothing is rejected), and thumbnails
/// of the captured card photos, each with a remove button so the
/// owner can see what was captured and replace it.
///
/// Pure UI — picking, OCR and the gallery guard live in [Step1Cnic].
class CnicCaptureSection extends StatelessWidget {
  final KycDraft draft;
  final bool scanningFront;
  final bool scanningBack;
  final void Function({required bool front, required bool fromGallery})
  onPick;
  final void Function({required bool front}) onRemove;

  const CnicCaptureSection({
    super.key,
    required this.draft,
    required this.scanningFront,
    required this.scanningBack,
    required this.onPick,
    required this.onRemove,
  });

  Widget _thumb(
    BuildContext context, {
    required String label,
    required XFile file,
    required Key removeKey,
    required VoidCallback onRemove,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(file.path),
                  height: 96,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image_rounded)),
                ),
              ),
              // 48dp hit area (same pattern as the extra-doc thumbs).
              Positioned(
                right: 0,
                top: 0,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    key: removeKey,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.cancel_rounded, size: 24),
                    onPressed: onRemove,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = this.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Both buttons stretch to the same height — in Urdu the
        // two labels wrap to different line counts. (The Row
        // needs IntrinsicHeight: stretch is illegal inside the
        // wizard's unbounded scroll view on its own.)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: scanningFront
                      ? null
                      : () => onPick(front: true, fromGallery: false),
                  icon: scanningFront
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.credit_card_rounded),
                  label: Text(
                    l10n.kycWizardScanFront,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: scanningBack
                      ? null
                      : () => onPick(front: false, fromGallery: false),
                  icon: scanningBack
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.flip_to_back_rounded),
                  label: Text(
                    l10n.kycWizardScanBack,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('step1_cnic_front_gallery'),
                onPressed: scanningFront
                    ? null
                    : () => onPick(front: true, fromGallery: true),
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                label: Text(l10n.kycWizardGalleryFront),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('step1_cnic_back_gallery'),
                onPressed: scanningBack
                    ? null
                    : () => onPick(front: false, fromGallery: true),
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                label: Text(l10n.kycWizardGalleryBack),
              ),
            ),
          ],
        ),
        if (draft.cnicFrontPhoto != null ||
            draft.cnicBackPhoto != null) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (draft.cnicFrontPhoto != null)
                _thumb(
                  context,
                  label: l10n.kycWizardFrontScanned,
                  file: draft.cnicFrontPhoto!,
                  removeKey: const ValueKey('step1_cnic_front_remove'),
                  onRemove: () => onRemove(front: true),
                ),
              if (draft.cnicFrontPhoto != null &&
                  draft.cnicBackPhoto != null)
                const SizedBox(width: 12),
              if (draft.cnicBackPhoto != null)
                _thumb(
                  context,
                  label: l10n.kycWizardBackScanned,
                  file: draft.cnicBackPhoto!,
                  removeKey: const ValueKey('step1_cnic_back_remove'),
                  onRemove: () => onRemove(front: false),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
