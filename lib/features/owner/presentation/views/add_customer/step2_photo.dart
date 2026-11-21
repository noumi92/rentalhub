import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/media_picker_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import 'finger_capture_section.dart';
import 'kyc_draft.dart';
import 'kyc_step.dart';

/// Wizard step 2 — live face photo + fingerprints (spec O13).
///
/// No face matching happens anywhere: the photo is saved and an
/// admin reviews it manually. The face is captured with the FRONT
/// camera; the fingerprints are a PHOTO of each hand's 4 fingers
/// (left + right, no thumbs) with the REAR camera — photos, never
/// scans (no fingerprint SDK in the app).
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

  @override
  Future<bool> validate() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    if (!draft.hasFacePhoto) {
      if (mounted) {
        AppFeedback.showError(context, l10n.kycWizardPhotoRequired);
      }
      return false;
    }
    if (!draft.hasLeftFingerprints || !draft.hasRightFingerprints) {
      if (mounted) {
        AppFeedback.showError(context, l10n.kycWizardFingerRequired);
      }
      return false;
    }
    return true;
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 10),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
    // Edit mode: the on-file face photo (URL) when no fresh
    // capture exists yet.
    final faceUrl = draft.existingUrlFor('profilePhotoUrl');
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
                  ? (faceUrl == null
                      ? const Icon(Icons.face_rounded, size: 64)
                      : Image.network(faceUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image_rounded)))
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
        // Audit 2026-11-15 (Team D find): Take + Retake + Remove in
        // one Row overflowed 108 px at 360 px once a face photo
        // exists — a Wrap lets the actions flow to a second line,
        // like the finger sections below.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('step2_face_take'),
              onPressed: _pickFace,
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(l10n.kycTakePhoto),
            ),
            if (draft.hasFacePhoto) ...[
              TextButton(
                key: const ValueKey('step2_face_retake'),
                onPressed: _pickFace,
                child: Text(l10n.kycWizardRetake),
              ),
              TextButton(
                key: const ValueKey('step2_face_remove'),
                onPressed: () {
                  setState(() {
                    draft.facePhoto = null;
                    draft.clearExisting('profilePhotoUrl');
                  });
                  widget.onChanged();
                },
                child: Text(l10n.kycWizardRemoveImage),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _section(l10n.kycWizardFingerprints),
        FingerCaptureSection(
          title: l10n.kycWizardLeftHand,
          photo: draft.leftFingersPhoto,
          existingUrl: draft.existingUrlFor('leftFingerprintUrl'),
          onCaptured: (file) {
            setState(() => draft.leftFingersPhoto = file);
          },
          onRemove: () {
            setState(() {
              draft.leftFingersPhoto = null;
              draft.clearExisting('leftFingerprintUrl');
            });
            widget.onChanged();
          },
          onChanged: widget.onChanged,
          scanButtonKey: const ValueKey('step2_finger_left_scan'),
          retakeButtonKey: const ValueKey('step2_finger_left_retake'),
          removeButtonKey: const ValueKey('step2_finger_left_remove'),
        ),
        const SizedBox(height: 20),
        FingerCaptureSection(
          title: l10n.kycWizardRightHand,
          photo: draft.rightFingersPhoto,
          existingUrl: draft.existingUrlFor('rightFingerprintUrl'),
          onCaptured: (file) {
            setState(() => draft.rightFingersPhoto = file);
          },
          onRemove: () {
            setState(() {
              draft.rightFingersPhoto = null;
              draft.clearExisting('rightFingerprintUrl');
            });
            widget.onChanged();
          },
          onChanged: widget.onChanged,
          scanButtonKey: const ValueKey('step2_finger_right_scan'),
          retakeButtonKey: const ValueKey('step2_finger_right_retake'),
          removeButtonKey: const ValueKey('step2_finger_right_remove'),
        ),
      ],
    );
  }
}
