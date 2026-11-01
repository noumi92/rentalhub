import 'dart:io';
import '../../domain/entities/kyc_document_entity.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource remoteDataSource;

  const KycRepositoryImpl({required this.remoteDataSource});

  @override
  Future<KycDocumentEntity> uploadKycDocuments({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
  }) =>
      remoteDataSource.uploadCnicAndLicense(
        userUid: userUid,
        cnicNumber: cnicNumber,
        cnicFront: cnicFront,
        cnicBack: cnicBack,
        license: license,
      );
}

