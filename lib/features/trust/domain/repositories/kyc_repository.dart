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
    // The status the caller already knows this record has (the
    // documents screen loaded it). A verified record re-submitted
    // becomes 'resubmitted', never 'submitted' — the data source
    // falls back to re-reading the record when this is null.
    String? previousStatus,
  });

  Future<KycDocumentEntity?> getKyc(String userUid);
}

