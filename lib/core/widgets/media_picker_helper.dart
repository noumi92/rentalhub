import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

class MediaPickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Shows camera/gallery/remove options or opens front camera directly for selfies.
  static Future<void> showMediaSourceSheet({
    required BuildContext context,
    required ValueChanged<XFile?> onImageSelected,
    bool frontCameraOnly = false,
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

    // Modal bottom sheet with Camera, Gallery, and optional Remove
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
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
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select Media Source',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
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
                title: Text('Take Photo (Back Camera)', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('Use device camera', style: Theme.of(ctx).textTheme.labelSmall),
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
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
                ),
                title: Text('Choose from Gallery', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('Pick existing photo or screenshot', style: Theme.of(ctx).textTheme.labelSmall),
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
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.accentDanger, size: 22),
                  ),
                  title: Text('Remove Photo', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentDanger)),
                  subtitle: Text('Clear this uploaded image', style: Theme.of(ctx).textTheme.labelSmall),
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

