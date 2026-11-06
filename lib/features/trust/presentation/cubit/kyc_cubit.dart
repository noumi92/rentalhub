import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/kyc_document_entity.dart';
import '../../domain/usecases/upload_kyc_document_usecase.dart';

abstract class KycState extends Equatable {
  const KycState();
  @override
  List<Object?> get props => [];
}

class KycInitial extends KycState {
  const KycInitial();
}

class KycUploading extends KycState {
  const KycUploading();
}

class KycSubmitted extends KycState {
  final KycDocumentEntity document;
  const KycSubmitted(this.document);
  @override
  List<Object?> get props => [document];
}

class KycError extends KycState {
  final String message;
  const KycError(this.message);
  @override
  List<Object?> get props => [message];
}

class KycCubit extends Cubit<KycState> {
  final UploadKycDocumentUseCase uploadKycUseCase;

  KycCubit({required this.uploadKycUseCase}) : super(const KycInitial());

  // G3: the photos travel with the submission now — the old version
  // accepted no files, so it "submitted" a CNIC number with keys
  // pointing at photos that were never uploaded.
  Future<void> submitKyc({
    required String userUid,
    required String cnicNumber,
    File? cnicFront,
    File? cnicBack,
    File? license,
  }) async {
    emit(const KycUploading());
    try {
      final doc = await uploadKycUseCase(
        userUid: userUid,
        cnicNumber: cnicNumber,
        cnicFront: cnicFront,
        cnicBack: cnicBack,
        license: license,
      );
      emit(KycSubmitted(doc));
    } catch (e) {
      emit(KycError(e.toString()));
    }
  }
}

