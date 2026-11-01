import 'dart:io';
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

    return KycDocumentEntity(
      userUid: userUid,
      cnicNumber: cnicNumber,
      cnicFrontKey: frontKey,
      cnicBackKey: backKey,
      licenseKey: licenseKey,
      status: 'submitted',
    );
  }
}

