import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/queued_upload.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../domain/entities/kyc_document_entity.dart';

class KycRemoteDataSource {
  final CPanelStorageClient storageClient;

  /// Phase B (B3): the persisted pending-write store. When set, a
  /// failed upload is queued instead of failing the submission.
  final OfflineSyncQueue? syncQueue;

  KycRemoteDataSource({required this.storageClient, this.syncQueue});

  /// Uploads one KYC file, or queues it when offline. Returns the
  /// cPanel key on success, '' when the file is queued (the queue
  /// handler writes the real key into the KYC doc on sync).
  Future<String> _uploadOrQueueFile({
    required String userUid,
    required File file,
    required String field,
  }) async {
    try {
      return await storageClient.uploadFile(
        file: file,
        userUid: userUid,
        folder: 'kyc',
      );
    } catch (_) {
      final queue = syncQueue;
      if (queue == null) rethrow;
      await enqueueUpload(
        file: file,
        userUid: userUid,
        folder: 'kyc',
        queue: queue,
        targetCollection: 'kyc_documents',
        targetDocId: userUid,
        targetField: field,
        extra: const {'status': 'submitted'},
        storeKey: true,
      );
      return '';
    }
  }

  Future<KycDocumentEntity> uploadCnicAndLicense({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
  }) async {
    String frontKey = '';
    String backKey = '';
    String licenseKey = '';

    if (cnicFront != null && cnicFront.existsSync()) {
      frontKey = await _uploadOrQueueFile(
        userUid: userUid,
        file: cnicFront,
        field: 'cnicFrontKey',
      );
    }
    if (cnicBack != null && cnicBack.existsSync()) {
      backKey = await _uploadOrQueueFile(
        userUid: userUid,
        file: cnicBack,
        field: 'cnicBackKey',
      );
    }
    if (license != null && license.existsSync()) {
      licenseKey = await _uploadOrQueueFile(
        userUid: userUid,
        file: license,
        field: 'licenseKey',
      );
    }

    final entity = KycDocumentEntity(
      userUid: userUid,
      cnicNumber: cnicNumber,
      cnicFrontKey: frontKey,
      cnicBackKey: backKey,
      licenseKey: licenseKey,
      status: 'submitted',
    );
    // G3: record the submission so the documents screen (and the owner
    // side) can show the real status instead of a hardcoded flag.
    // Phase B (B4): merge semantics + server timestamp; on failure
    // the record itself is queued (the files are already queued
    // above, so nothing is lost).
    final record = <String, dynamic>{
      'userUid': userUid,
      'cnicNumber': cnicNumber,
      'cnicFrontKey': frontKey,
      'cnicBackKey': backKey,
      'licenseKey': licenseKey,
      'status': 'submitted',
    };
    try {
      await FirebaseFirestore.instance
          .collection('kyc_documents')
          .doc(userUid)
          .set(
        {
          ...record,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      final queue = syncQueue;
      if (queue != null) {
        await queue.enqueue(
          kind: 'firestore_set',
          entityId: userUid,
          payload: {
            'collection': 'kyc_documents',
            'docId': userUid,
            'fields': record,
          },
        );
      }
    }
    return entity;
  }

  /// G3: the customer's submitted KYC record, if any.
  Future<KycDocumentEntity?> getKyc(String userUid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('kyc_documents')
          .doc(userUid)
          .get();
      final d = doc.data();
      if (d == null) return null;
      return KycDocumentEntity(
        userUid: userUid,
        cnicNumber: d['cnicNumber'] as String? ?? '',
        cnicFrontKey: d['cnicFrontKey'] as String? ?? '',
        cnicBackKey: d['cnicBackKey'] as String? ?? '',
        licenseKey: d['licenseKey'] as String? ?? '',
        status: d['status'] as String? ?? 'submitted',
      );
    } catch (_) {
      return null;
    }
  }
}

