import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/queued_upload.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';

/// Uploads a picked vehicle photo to cPanel and returns its signed URL.
///
/// Phase B (B3): when the upload fails the photo is queued instead
/// of lost — the file is copied into the queue dir and an `'upload'`
/// entry targets `vehicles/{vehicleId}` `imageUrl`, so the real URL
/// lands on the vehicle when the device is back online. The caller
/// falls back to the local path (the car still shows its photo on
/// this phone); the queue handler overwrites it with the real URL.
/// Without a [vehicleId] (or without a queue) the old behaviour
/// applies: the local path is returned on failure.
class VehiclePhotoUploadService {
  static Future<String?> uploadFrontPhoto({
    required String shopId,
    required XFile? photo,
    String? vehicleId,
    OfflineSyncQueue? syncQueue,
  }) async {
    if (photo == null) return null;
    final cpanel = sl<CPanelStorageClient>();
    final queue = syncQueue ??
        (sl.isRegistered<OfflineSyncQueue>() ? sl<OfflineSyncQueue>() : null);
    if (queue != null && vehicleId != null) {
      return await uploadOrQueue(
            client: cpanel,
            file: File(photo.path),
            userUid: shopId,
            folder: 'vehicles',
            queue: queue,
            targetCollection: 'vehicles',
            targetDocId: vehicleId,
            targetField: 'imageUrl',
          ) ??
          photo.path;
    }
    try {
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
