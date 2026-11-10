import 'dart:io';
import '../entities/kyc_document_entity.dart';

abstract class KycRepository {
  Future<KycDocumentEntity> uploadKycDocuments({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
    File? licenseBack,
    String? licenseNumber,
    String? licenseExpiry,
    // The CNIC back-QR number: written to the restricted
    // `customer_qr_codes/{userUid}` doc, never onto this record.
    String? qrCode,
  });

  Future<KycDocumentEntity?> getKyc(String userUid);
}

