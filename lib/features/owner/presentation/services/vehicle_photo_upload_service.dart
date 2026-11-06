import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';

/// Uploads a picked vehicle photo to cPanel and returns its signed URL.
/// Falls back to the local file path when the upload fails, so the car
/// still shows its photo on this phone. If the cPanel endpoint rejects
/// the 'vehicles' folder, add it server-side — the save still succeeds.
class VehiclePhotoUploadService {
  static Future<String?> uploadFrontPhoto({
    required String shopId,
    required XFile? photo,
  }) async {
    if (photo == null) return null;
    try {
      final cpanel = sl<CPanelStorageClient>();
      final key = await cpanel.uploadFile(
        file: File(photo.path),
        userUid: shopId,
        folder: 'vehicles',
      );
      return cpanel.getSignedMediaUrl(key, shopId);
    } catch (_) {
      return photo.path;
    }
  }
}
