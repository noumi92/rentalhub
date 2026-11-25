import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/queued_upload.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../domain/entities/kyc_document_entity.dart';
import '../services/customer_qr_code_service.dart';

class KycRemoteDataSource {
  final CPanelStorageClient storageClient;

  /// Phase B (B3): the persisted pending-write store. When set, a
  /// failed upload is queued instead of failing the submission.
  final OfflineSyncQueue? syncQueue;
  final FirebaseFirestore? _firestore;

  KycRemoteDataSource({
    required this.storageClient,
    this.syncQueue,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  /// Injected Firestore in tests (FakeFirebaseFirestore); the real
  /// singleton in the app — the same pattern CustomerRemoteDataSource
  /// uses.
  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Uploads one KYC file, or queues it when offline. Returns the
  /// cPanel key on success, '' when the file is queued (the queue
  /// handler writes the real key into the KYC doc on sync).
  Future<String> _uploadOrQueueFile({
    required String userUid,
    required File file,
    required String field,
    String statusForQueue = 'submitted',
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
        extra: {'status': statusForQueue},
        storeKey: true,
      );
      return '';
    }
  }

  /// Profile hub (2026-11-25): a re-submission must never demote a
  /// verified record and must never wipe stored files. A verified
  /// record re-submitted becomes 'resubmitted' — pending re-review,
  /// visible in the admin queue alongside 'submitted' — and a slot
  /// with no newly picked file keeps its stored key. Licence
  /// number/expiry likewise keep their stored values unless the
  /// caller supplies new ones.
  Future<KycDocumentEntity> uploadCnicAndLicense({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
    File? licenseBack,
    String? licenseNumber,
    String? licenseExpiry,
    String? qrCode,
    String? previousStatus,
  }) async {
    // The stored record, best-effort: when the caller already knows
    // the status (the documents screen loaded it) that wins for the
    // status decision, so an offline re-submit cannot demote a
    // verified record just because this read failed.
    final existing = await getKyc(userUid);
    final priorStatus = previousStatus ?? existing?.status;
    final newStatus =
        priorStatus == 'verified' ? 'resubmitted' : 'submitted';

    String frontKey = existing?.cnicFrontKey ?? '';
    String backKey = existing?.cnicBackKey ?? '';
    String licenseKey = existing?.licenseKey ?? '';
    String licenseBackKey = existing?.licenseBackKey ?? '';
    // Only a newly picked file replaces a stored key. A picked file
    // whose upload is queued still replaces it — the queue handler
    // writes the real key into the same field on sync.
    if (cnicFront != null && cnicFront.existsSync()) {
      frontKey = await _uploadOrQueueFile(
        userUid: userUid,
        file: cnicFront,
        field: 'cnicFrontKey',
        statusForQueue: newStatus,
      );
    }
    if (cnicBack != null && cnicBack.existsSync()) {
      backKey = await _uploadOrQueueFile(
        userUid: userUid,
        file: cnicBack,
        field: 'cnicBackKey',
        statusForQueue: newStatus,
      );
    }
    if (license != null && license.existsSync()) {
      licenseKey = await _uploadOrQueueFile(
        userUid: userUid,
        file: license,
        field: 'licenseKey',
        statusForQueue: newStatus,
      );
    }
    if (licenseBack != null && licenseBack.existsSync()) {
      licenseBackKey = await _uploadOrQueueFile(
        userUid: userUid,
        file: licenseBack,
        field: 'licenseBackKey',
        statusForQueue: newStatus,
      );
    }

    final mergedLicenseNumber =
        licenseNumber ?? existing?.licenseNumber ?? '';
    final mergedLicenseExpiry =
        licenseExpiry ?? existing?.licenseExpiry ?? '';

    final entity = KycDocumentEntity(
      userUid: userUid,
      cnicNumber: cnicNumber,
      cnicFrontKey: frontKey,
      cnicBackKey: backKey,
      licenseKey: licenseKey,
      licenseBackKey: licenseBackKey,
      licenseNumber: mergedLicenseNumber,
      licenseExpiry: mergedLicenseExpiry,
      status: newStatus,
    );
    // G3: record the submission so the documents screen (and the owner
    // side) can show the real status instead of a hardcoded flag.
    // Phase B (B4): merge semantics + server timestamp; on failure
    // the record itself is queued (the files are already queued
    // above, so nothing is lost).
    final record = <String, dynamic>{
      'userUid': userUid,
      'cnicNumber': cnicNumber,
      'licenseNumber': mergedLicenseNumber,
      'licenseExpiry': mergedLicenseExpiry,
      'status': newStatus,
    };
    // File keys: write the merged values when the stored record was
    // read (or this is a first submission and there is nothing to
    // preserve). When a record is known to exist but the read failed
    // (offline), omit the unpicked keys so the merge keeps the stored
    // values instead of wiping them with ''.
    if (existing != null || previousStatus == null) {
      record['cnicFrontKey'] = frontKey;
      record['cnicBackKey'] = backKey;
      record['licenseKey'] = licenseKey;
      record['licenseBackKey'] = licenseBackKey;
    } else {
      if (cnicFront != null) record['cnicFrontKey'] = frontKey;
      if (cnicBack != null) record['cnicBackKey'] = backKey;
      if (license != null) record['licenseKey'] = licenseKey;
      if (licenseBack != null) record['licenseBackKey'] = licenseBackKey;
    }
    // The CNIC back-QR number goes to the restricted
    // `customer_qr_codes/{userUid}` doc, never onto this record — a
    // best-effort write that must not fail the submission.
    final qr = qrCode?.trim() ?? '';
    if (qr.isNotEmpty) {
      await CustomerQrCodeService(syncQueue: syncQueue).saveQrCode(
        customerId: userUid,
        qrCode: qr,
      );
    }
    final fs = _resolvedFirestore;
    try {
      if (fs == null) throw StateError('no firestore');
      await fs
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

  /// Profile hub (2026-11-25): the customer changed their CNIC in
  /// the edit-profile flow while their KYC was verified. The stored
  /// documents no longer match the new number, so the record goes
  /// back for review as 'resubmitted' — visible in the admin queue,
  /// and the admin's next decision ('verified' / 'rejected') lands
  /// on it as usual. Nothing else on the record is touched.
  /// Non-verified records need no flag: they are already pending.
  Future<void> flagForReReview(String userUid) async {
    final existing = await getKyc(userUid);
    if (existing == null || existing.status != 'verified') return;
    final fs = _resolvedFirestore;
    try {
      if (fs == null) throw StateError('no firestore');
      await fs
          .collection('kyc_documents')
          .doc(userUid)
          .set(
        {
          'status': 'resubmitted',
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
            'fields': {'status': 'resubmitted'},
          },
        );
      }
    }
  }

  /// Profile hub (2026-11-25): keep the two CNIC sources of truth
  /// in step. `customers/{uid}.cnic` is written by the edit-profile
  /// save; this merge-writes the same number onto
  /// `kyc_documents/{uid}.cnicNumber` when a KYC record exists, so
  /// an edited CNIC can never silently diverge from the documents.
  /// No record, no write.
  Future<void> syncCnicNumber(String userUid, String cnicNumber) async {
    final existing = await getKyc(userUid);
    if (existing == null) return;
    if (existing.cnicNumber == cnicNumber) return;
    final fs = _resolvedFirestore;
    if (fs == null) return;
    try {
      await fs
          .collection('kyc_documents')
          .doc(userUid)
          .set(
        {
          'cnicNumber': cnicNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  /// G3: the customer's submitted KYC record, if any.
  Future<KycDocumentEntity?> getKyc(String userUid) async {
    final fs = _resolvedFirestore;
    if (fs == null) return null;
    try {
      final doc = await fs
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
        licenseBackKey: d['licenseBackKey'] as String? ?? '',
        licenseNumber: d['licenseNumber'] as String? ?? '',
        licenseExpiry: d['licenseExpiry'] as String? ?? '',
        status: d['status'] as String? ?? 'submitted',
      );
    } catch (_) {
      return null;
    }
  }
}

