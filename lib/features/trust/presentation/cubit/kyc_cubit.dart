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

  Future<void> submitKyc({
    required String userUid,
    required String cnicNumber,
  }) async {
    emit(const KycUploading());
    try {
      final doc = await uploadKycUseCase(
        userUid: userUid,
        cnicNumber: cnicNumber,
      );
      emit(KycSubmitted(doc));
    } catch (e) {
      emit(KycError(e.toString()));
    }
  }
}

