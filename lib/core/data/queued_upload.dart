import 'dart:io';

import '../network/cpanel_storage_client.dart';
import 'offline_sync_queue.dart';
import 'queued_uploads.dart';

/// Phase B (B3): stores [file] in the queue dir and enqueues an
/// `'upload'` entry for it. The upload handler (a) uploads the
/// file, (b) writes the resulting URL — or the file key when
/// [storeKey] is true — into [targetCollection]/[targetDocId]/
/// [targetField], plus [extra] fields. A re-submitted file for the
/// same target field supersedes the previous queued one.
Future<void> enqueueUpload({
  required File file,
  required String userUid,
  required String folder,
  required OfflineSyncQueue queue,
  required String targetCollection,
  required String targetDocId,
  required String targetField,
  Map<String, dynamic> extra = const {},
  bool storeKey = false,
}) async {
  final queuedPath = await QueuedUploads.store(file);
  await queue.enqueue(
    kind: 'upload',
    entityId: targetDocId,
    payload: {
      'filePath': queuedPath,
      'queuedPath': true,
      'folder': folder,
      'userUid': userUid,
      'targetCollection': targetCollection,
      'targetDocId': targetDocId,
      'targetField': targetField,
      'extra': extra,
      'storeKey': storeKey,
    },
    dedupeKey: 'upload:$targetDocId:$targetField',
    replaceExisting: true,
  );
}
///
/// Tries the upload. On success returns the signed media URL. On
/// failure it **never** returns a made-up URL and **never** drops
/// the file: the file is copied into the queue dir and an `'upload'`
/// entry is enqueued (targeting [targetCollection]/[targetDocId]/
/// [targetField]), and null is returned so the caller records "not
/// yet uploaded" honestly. The queue handler uploads the file when
/// the device is back online and writes the real URL into the
/// target doc.
///
/// A re-submitted file for the same target field supersedes the
/// previous queued one (same dedupe key, replaced) — one field,
/// one pending upload.
Future<String?> uploadOrQueue({
  required CPanelStorageClient client,
  required File file,
  required String userUid,
  required String folder,
  required OfflineSyncQueue queue,
  required String targetCollection,
  required String targetDocId,
  required String targetField,
  Map<String, dynamic> extra = const {},
}) async {
  try {
    final key = await client.uploadFile(
      file: file,
      userUid: userUid,
      folder: folder,
    );
    return client.getSignedMediaUrl(key, userUid);
  } catch (_) {
    try {
      await enqueueUpload(
        file: file,
        userUid: userUid,
        folder: folder,
        queue: queue,
        targetCollection: targetCollection,
        targetDocId: targetDocId,
        targetField: targetField,
        extra: extra,
      );
    } catch (_) {
      // Even the queue failed (e.g. prefs unavailable): the caller
      // still gets null, never a fake URL. The file itself is lost
      // only if the device storage is gone — nothing more we can do
      // from here.
    }
    return null;
  }
}
