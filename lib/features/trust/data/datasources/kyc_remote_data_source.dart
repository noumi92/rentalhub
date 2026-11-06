import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/network/cpanel_storage_client.dart';
import '../../domain/entities/kyc_document_entity.dart';

class KycRemoteDataSource {
  final CPanelStorageClient storageClient;

  KycRemoteDataSource({required this.storageClient});

  Future<KycDocumentEntity> uploadCnicAndLicense({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
  }) async {
    String frontKey = 'kyc/${userUid}_cnic_front.jpg';
    String backKey = 'kyc/${userUid}_cnic_back.jpg';
    String licenseKey = 'kyc/${userUid}_license.jpg';

    if (cnicFront != null && cnicFront.existsSync()) {
      frontKey = await storageClient.uploadFile(
        file: cnicFront,
        userUid: userUid,
        folder: 'kyc',
      );
    }
    if (cnicBack != null && cnicBack.existsSync()) {
      backKey = await storageClient.uploadFile(
        file: cnicBack,
        userUid: userUid,
        folder: 'kyc',
      );
    }
    if (license != null && license.existsSync()) {
      licenseKey = await storageClient.uploadFile(
        file: license,
        userUid: userUid,
        folder: 'kyc',
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
    try {
      await FirebaseFirestore.instance
          .collection('kyc_documents')
          .doc(userUid)
          .set({
        'userUid': userUid,
        'cnicNumber': cnicNumber,
        'cnicFrontKey': frontKey,
        'cnicBackKey': backKey,
        'licenseKey': licenseKey,
        'status': 'submitted',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
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

