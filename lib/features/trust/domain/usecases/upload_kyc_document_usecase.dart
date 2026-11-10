import 'dart:io';
import '../entities/kyc_document_entity.dart';
import '../repositories/kyc_repository.dart';

class UploadKycDocumentUseCase {
  final KycRepository repository;
  const UploadKycDocumentUseCase(this.repository);

  Future<KycDocumentEntity> call({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
    File? licenseBack,
    String? licenseNumber,
    String? licenseExpiry,
    String? qrCode,
  }) =>
      repository.uploadKycDocuments(
        userUid: userUid,
        cnicNumber: cnicNumber,
        cnicFront: cnicFront,
        cnicBack: cnicBack,
        license: license,
        licenseBack: licenseBack,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        qrCode: qrCode,
      );
}

