import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

class MediaPickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Shows camera/gallery/remove options or opens front camera directly for selfies.
  ///
  /// [cameraOnly] is the KYC document rule (CNIC + driving license):
  /// the rear camera opens directly and no gallery option is offered
  /// — a gallery photo is never accepted for these uploads. Other
  /// pickers (vehicle photos, bills, extra docs) keep the sheet.
  static Future<void> showMediaSourceSheet({
    required BuildContext context,
    required ValueChanged<XFile?> onImageSelected,
    bool frontCameraOnly = false,
    bool cameraOnly = false,
    bool hasExistingFile = false,
  }) async {
    // If front-camera only (e.g. live selfie verification), immediately launch front camera
    if (frontCameraOnly) {
      try {
        final photo = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 85,
        );
        if (photo != null) {
          onImageSelected(photo);
        }
      } catch (e) {
        debugPrint('Front camera pick error: $e');
      }
      return;
    }

    // KYC documents: rear camera directly, no sheet, no gallery.
    if (cameraOnly) {
      try {
        final photo = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 85,
        );
        if (photo != null) {
          onImageSelected(photo);
        }
      } catch (e) {
        debugPrint('Rear camera pick error: $e');
      }
      return;
    }

    // Modal bottom sheet with Camera, Gallery, and optional Remove
    // Phase F: the sheet copy is localized (English fallback for
    // delegate-less pumps — the hardware-mock test pumps without
    // delegates and asserts the English copy).
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n?.mediaSelectSource ?? 'Select Media Source',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              // Camera Option (Back Camera)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.secondary, size: 22),
                ),
                title: Text(l10n?.mediaTakePhoto ?? 'Take Photo (Back Camera)', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text(l10n?.mediaTakePhotoHint ?? 'Use device camera', style: Theme.of(ctx).textTheme.labelSmall),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final photo = await _picker.pickImage(
                    source: ImageSource.camera,
                    preferredCameraDevice: CameraDevice.rear,
                    imageQuality: 85,
                  );
                  if (photo != null) onImageSelected(photo);
                },
              ),

              // Gallery Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, size: 22),
                ),
                title: Text(l10n?.avatarFromGallery ?? 'Choose from Gallery', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text(l10n?.mediaChooseGalleryHint ?? 'Pick existing photo or screenshot', style: Theme.of(ctx).textTheme.labelSmall),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final photo = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (photo != null) onImageSelected(photo);
                },
              ),

              // Remove Photo Option (if exists)
              if (hasExistingFile) ...[
                const Divider(height: 10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentDanger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: AppColors.dangerTextFor(Theme.of(context).brightness), size: 22),
                  ),
                  title: Text(l10n?.mediaRemovePhoto ?? 'Remove Photo', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.dangerTextFor(Theme.of(context).brightness))),
                  subtitle: Text(l10n?.mediaRemovePhotoHint ?? 'Clear this uploaded image', style: Theme.of(ctx).textTheme.labelSmall),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onImageSelected(null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

