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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Select Media Source',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.midnightNavy,
                ),
              ),
              const SizedBox(height: 12),

              // Camera Option (Back Camera)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sunsetOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.sunsetOrange, size: 22),
                ),
                title: const Text('Take Photo (Back Camera)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Use device camera', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.midnightNavy, size: 22),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Pick existing photo or screenshot', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.error)),
                  subtitle: const Text('Clear this uploaded image', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

