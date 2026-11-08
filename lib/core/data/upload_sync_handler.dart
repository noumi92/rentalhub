import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../network/cpanel_storage_client.dart';
import 'queued_uploads.dart';
import 'sync_engine.dart';
import 'sync_queue_entry.dart';

/// Phase B (B3): the generic cPanel-upload queue handler (kind
/// `'upload'`).
///
/// Payload contract (see [SyncQueueEntry]):
/// * `filePath` — a file copied into the queue dir by
///   [QueuedUploads.store] (`queuedPath: true`), **or** `fileB64` +
///   `fileName` for a small inline file.
/// * `folder` — the cPanel category (`vehicles`, `kyc`, `payments`,
///   `handovers`, `agreements`).
/// * `userUid` — the HMAC identity for the upload.
/// * `targetCollection` / `targetDocId` / `targetField` (optional) —
///   after a successful upload the URL is written into that doc
///   with merge semantics + a server timestamp, plus `extra` fields.
///
/// Idempotency: once the upload succeeds, the URL is stored in
/// `entry.result['remoteUrl']` and the local file copy is deleted.
/// A retry then skips the upload entirely and only retries the
/// Firestore write — a failed first attempt never creates a second
/// file on the server.
class UploadSyncHandler {
  final CPanelStorageClient? storageClient;
  final FirebaseFirestore? _firestore;

  UploadSyncHandler({this.storageClient, FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<bool> call(SyncQueueEntry entry, SyncEngine engine) async {
    final payload = entry.payload;
    final client = storageClient;
    if (client == null) return false;

    final existingUrl = entry.result['remoteUrl'] as String?;
    String? url = existingUrl;
    String? fileKey = entry.result['fileKey'] as String?;
    if (url == null) {
      final file = await _resolveFile(payload);
      // Phone-test #4: the queued file is already gone locally (the
      // picked file was deleted before the retry). No retry can ever
      // succeed, so discard the entry instead of returning false
      // forever and sticking the banner on "1 pending sync".
      if (file == null) {
        debugPrint(
          'UploadSyncHandler: discarding ${entry.id} — local file for '
          'kind "${entry.kind}" no longer exists.',
        );
        await engine.queue.remove(entry.id);
        return true;
      }
      try {
        final key = await client.uploadFile(
          file: file,
          userUid: (payload['userUid'] as String?) ?? '',
          folder: (payload['folder'] as String?) ?? 'handovers',
        );
        url = client.getSignedMediaUrl(
          key,
          (payload['userUid'] as String?) ?? '',
        );
        fileKey = key;
        await engine.updateEntry(entry.copyWith(result: {
          ...entry.result,
          'remoteUrl': url,
          'fileKey': key,
        }));
        // The server has the file now — drop the local copy (only
        // when the caller queued it via QueuedUploads, or when we
        // materialized it from base64 ourselves).
        if (payload['queuedPath'] == true) {
          await QueuedUploads.delete(file.path);
        } else if (payload['fileB64'] != null) {
          await QueuedUploads.delete(file.path);
        }
      } catch (_) {
        return false;
      }
    }

    final targetCollection = payload['targetCollection'] as String?;
    final targetDocId = payload['targetDocId'] as String?;
    final targetField = payload['targetField'] as String?;
    if (targetCollection == null ||
        targetDocId == null ||
        targetField == null) {
      return true;
    }
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      final extra = payload['extra'] != null
          ? Map<String, dynamic>.from(payload['extra'] as Map)
          : <String, dynamic>{};
      // Phase B (B3): KYC docs store the file *key* (the screen
      // signs it at display time); everything else stores the URL.
      final value = payload['storeKey'] == true ? (fileKey ?? url) : url;
      await fs.collection(targetCollection).doc(targetDocId).set(
        {
          targetField: value,
          'updatedAt': FieldValue.serverTimestamp(),
          ...extra,
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resolves the payload to a readable file, or null.
  Future<File?> _resolveFile(Map<String, dynamic> payload) async {
    final path = payload['filePath'] as String?;
    if (path != null) {
      final file = File(path);
      return await file.exists() ? file : null;
    }
    final b64 = payload['fileB64'] as String?;
    final name = (payload['fileName'] as String?) ?? 'upload';
    if (b64 == null) return null;
    try {
      final tmp =
          File('${Directory.systemTemp.path}/queued-$name-${DateTime.now().millisecondsSinceEpoch}');
      await tmp.writeAsBytes(base64Decode(b64));
      return tmp;
    } catch (_) {
      return null;
    }
  }
}
