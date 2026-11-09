import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/media_picker_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import 'kyc_draft.dart';
import 'kyc_step.dart';

/// Wizard step 2 — live face photo + thumbprint (spec O13).
///
/// No face matching happens anywhere: the photos are saved and an
/// admin reviews them manually. The face is captured with the FRONT
/// camera; the thumbprint with the REAR camera.
class Step2Photo extends StatefulWidget {
  final KycDraft draft;
  final VoidCallback onChanged;

  const Step2Photo({super.key, required this.draft, required this.onChanged});

  @override
  Step2PhotoState createState() => Step2PhotoState();
}

class Step2PhotoState extends KycStepState<Step2Photo> {
  Future<void> _pickFace() async {
    await MediaPickerHelper.showMediaSourceSheet(
      context: context,
      frontCameraOnly: true,
      onImageSelected: (file) {
        if (file == null || !mounted) return;
        setState(() => widget.draft.facePhoto = file);
        widget.onChanged();
      },
    );
  }

  Future<void> _pickThumbprint() async {
    await MediaPickerHelper.showMediaSourceSheet(
      context: context,
      onImageSelected: (file) {
        if (file == null || !mounted) return;
        setState(() => widget.draft.thumbprintPhoto = file);
        widget.onChanged();
      },
    );
  }

  @override
  Future<bool> validate() async {
    final ok = widget.draft.hasFacePhoto && widget.draft.hasThumbprint;
    if (!ok && mounted) {
      AppFeedback.showError(
        context,
        AppLocalizations.of(context)!.kycWizardPhotoRequired,
      );
    }
    return ok;
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 10),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    ),
  );

  Widget _photoImage(XFile file, {required BoxFit fit}) => Image.file(
    File(file.path),
    fit: fit,
    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(l10n.kycWizardLivePhoto),
        Center(
          child: ClipOval(
            child: Container(
              width: 128,
              height: 128,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: draft.facePhoto == null
                  ? const Icon(Icons.face_rounded, size: 64)
                  : _photoImage(draft.facePhoto!, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kycWizardFaceHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('step2_face_take'),
              onPressed: _pickFace,
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(l10n.kycTakePhoto),
            ),
            if (draft.hasFacePhoto) ...[
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('step2_face_retake'),
                onPressed: _pickFace,
                child: Text(l10n.kycWizardRetake),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _section(l10n.kycWizardThumbprint),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: draft.thumbprintPhoto == null
              ? const Center(child: Icon(Icons.fingerprint_rounded, size: 48))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _photoImage(
                    draft.thumbprintPhoto!,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kycWizardThumbHint,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              key: const ValueKey('step2_thumb_take'),
              onPressed: _pickThumbprint,
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(l10n.kycTakePhoto),
            ),
            if (draft.hasThumbprint) ...[
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('step2_thumb_retake'),
                onPressed: _pickThumbprint,
                child: Text(l10n.kycWizardRetake),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
