import 'dart:io';
import '../entities/kyc_document_entity.dart';

abstract class KycRepository {
  Future<KycDocumentEntity> uploadKycDocuments({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
  });

  Future<KycDocumentEntity?> getKyc(String userUid);
}

