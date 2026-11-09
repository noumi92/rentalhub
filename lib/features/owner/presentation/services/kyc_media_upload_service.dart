import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/data/offline_sync_queue.dart';
import '../../../../../core/data/queued_upload.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/cpanel_storage_client.dart';
import '../views/add_customer/kyc_draft.dart';

/// What happened to one file.
enum KycUploadStatus {
  /// Uploaded now; [KycUploadResult.urls] carries the signed URL.
  uploaded,

  /// Upload failed (offline) but the file was queued: the queue
  /// handler uploads it when the device is back online and writes
  /// the real URL into the customer doc. The field is left off the
  /// saved record until then — never a fake or local-path URL.
  queued,

  /// Upload failed and even the queue refused it. The caller must
  /// abort the save and say so honestly.
  failed,
}

/// Per-file outcome of [KycMediaUploadService.uploadAll].
class KycUploadResult {
  /// field name → signed URL, for files uploaded right now.
  final Map<String, String> urls = {};

  /// Fields whose file was queued for later upload.
  final List<String> queuedFields = [];

  /// Fields whose file could not be uploaded or queued.
  final List<String> failedFields = [];

  bool get hasFailures => failedFields.isNotEmpty;
  int get queuedCount => queuedFields.length;
}

/// Uploads the wizard's KYC media to the cPanel storage API, folder
/// `kyc` (the same folder doc1/doc3 reserve for KYC documents).
///
/// Contract, per file (all media the wizard captures):
/// * direct upload wins → the signed URL is returned and stored on
///   the customer record;
/// * on failure the file is queued ([enqueueUpload]) targeting
///   `customers/{customerId}/{field}` — the queue handler writes the
///   real URL into the doc when the device is back online, and the
///   field is left off the record until then;
/// * if even the queue fails, the field is reported as failed and
///   the caller must not claim the save succeeded.
///
/// URLs are stored (not file keys): the customer fields are named
/// `*Url`, matching the vehicle flow. The customer-side KYC
/// submission flow stores keys instead — that is a different flow
/// and is untouched here.
///
/// Extra documents are the exception: they live in one list field
/// (`extraDocumentUrls`) which the queue handler cannot append to,
/// so an extra doc that cannot be uploaded right now is reported
/// as failed instead of queued. The save reports that honestly and
/// the owner can re-add the doc; nothing is silently dropped from
/// a required field.
class KycMediaUploadService {
  static const String folder = 'kyc';

  final CPanelStorageClient _client;
  final OfflineSyncQueue? _queue;

  KycMediaUploadService({CPanelStorageClient? client, OfflineSyncQueue? queue})
      : _client = client ?? sl<CPanelStorageClient>(),
        _queue = queue ??
            (sl.isRegistered<OfflineSyncQueue>()
                ? sl<OfflineSyncQueue>()
                : null);

  /// Uploads every file in [draft] (plus the signature PNG bytes).
  /// Files that are null are skipped. Extra documents are uploaded
  /// one by one; their URLs land in [KycUploadResult.urls] under
  /// `extraDocumentUrls_0`, `extraDocumentUrls_1`, … and the caller
  /// assembles the list from them in index order.
  Future<KycUploadResult> uploadAll({
    required String shopId,
    required String customerId,
    required KycDraft draft,
  }) async {
    final result = KycUploadResult();
    final files = <String, XFile?>{
      'profilePhotoUrl': draft.facePhoto,
      'thumbprintUrl': draft.thumbprintPhoto,
      'cnicFrontUrl': draft.cnicFrontPhoto,
      'cnicBackUrl': draft.cnicBackPhoto,
      'licenseFrontUrl': draft.licenseFrontPhoto,
      'licenseBackUrl': draft.licenseBackPhoto,
      'utilityBillUrl': draft.utilityBillPhoto,
    };
    for (final entry in files.entries) {
      await _uploadOne(
        result: result,
        shopId: shopId,
        customerId: customerId,
        field: entry.key,
        file: entry.value,
        queueable: true,
      );
    }
    for (var i = 0; i < draft.extraPhotos.length; i++) {
      await _uploadOne(
        result: result,
        shopId: shopId,
        customerId: customerId,
        field: 'extraDocumentUrls_$i',
        file: draft.extraPhotos[i],
        queueable: false,
      );
    }
    if (draft.signaturePng != null && draft.signaturePng!.isNotEmpty) {
      final file = await _writeTempPng(customerId, draft.signaturePng!);
      await _uploadOne(
        result: result,
        shopId: shopId,
        customerId: customerId,
        field: 'signatureUrl',
        file: file,
        queueable: true,
      );
    }
    return result;
  }

  Future<XFile?> _writeTempPng(String customerId, Uint8List png) async {
    try {
      final file = File(
        '${Directory.systemTemp.path}/kyc_signature_$customerId.png',
      );
      await file.writeAsBytes(png, flush: true);
      return XFile(file.path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _uploadOne({
    required KycUploadResult result,
    required String shopId,
    required String customerId,
    required String field,
    required XFile? file,
    required bool queueable,
  }) async {
    if (file == null) return;
    try {
      final key = await _client.uploadFile(
        file: File(file.path),
        userUid: shopId,
        folder: folder,
      );
      result.urls[field] = _client.getSignedMediaUrl(key, shopId);
      return;
    } catch (_) {
      // Fall through to the queue / failure handling below.
    }
    final queue = _queue;
    if (queueable && queue != null) {
      try {
        await enqueueUpload(
          file: File(file.path),
          userUid: shopId,
          folder: folder,
          queue: queue,
          targetCollection: 'customers',
          targetDocId: customerId,
          targetField: field,
        );
        result.queuedFields.add(field);
        return;
      } catch (_) {
        // Even the queue failed — reported as failed below.
      }
    }
    result.failedFields.add(field);
  }
}
