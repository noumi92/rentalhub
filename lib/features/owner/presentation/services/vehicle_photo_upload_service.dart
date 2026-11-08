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
///
/// Audit §5: the wizard picks 7 files (4 photos + 3 documents) but
/// only the front photo was ever uploaded — the other 6 were silently
/// discarded. [uploadAllVehicleFiles] uploads every picked file, each
/// to its own target field on the vehicle doc (`photoBackUrl`,
/// `photoSideUrl`, `photoInteriorUrl`, `regBookUrl`, `tokenTaxUrl`,
/// `insuranceUrl`); the vehicle write uses merge semantics, so the
/// queued field writes never clobber the vehicle doc created after
/// them. The returned map is field → signed URL (or the local path
/// when the upload is queued / falls back). Callers must upload —
/// never silently drop a picked file.
class VehiclePhotoUploadService {
  static Future<String?> uploadFrontPhoto({
    required String shopId,
    required XFile? photo,
    String? vehicleId,
    OfflineSyncQueue? syncQueue,
  }) async {
    return uploadVehicleFile(
      shopId: shopId,
      photo: photo,
      vehicleId: vehicleId,
      targetField: 'imageUrl',
      syncQueue: syncQueue,
    );
  }

  /// Uploads one picked file to the `vehicles` folder, targeting
  /// [targetField] on `vehicles/{vehicleId}` when a queue + id exist.
  /// Returns the signed URL, or the local path when the upload was
  /// queued (the queue handler writes the real URL later) or failed
  /// without a queue. Returns null when [photo] is null.
  static Future<String?> uploadVehicleFile({
    required String shopId,
    required XFile? photo,
    String? vehicleId,
    String targetField = 'imageUrl',
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
            targetField: targetField,
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

  /// Uploads every picked file in [files] (target field → picked
  /// file; null entries are skipped) and returns the same keys mapped
  /// to their signed URL or local fallback path. Uploads run
  /// sequentially so a failure in one file never drops another.
  static Future<Map<String, String?>> uploadAllVehicleFiles({
    required String shopId,
    required String vehicleId,
    required Map<String, XFile?> files,
    OfflineSyncQueue? syncQueue,
  }) async {
    final uploaded = <String, String?>{};
    for (final entry in files.entries) {
      if (entry.value == null) continue;
      uploaded[entry.key] = await uploadVehicleFile(
        shopId: shopId,
        photo: entry.value,
        vehicleId: vehicleId,
        targetField: entry.key,
        syncQueue: syncQueue,
      );
    }
    return uploaded;
  }
}
