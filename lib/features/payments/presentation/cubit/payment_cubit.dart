import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/domain/repositories/booking_repository.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentUploading extends PaymentState {
  const PaymentUploading();
}

class PaymentSubmittedSuccess extends PaymentState {
  final BookingEntity booking;
  const PaymentSubmittedSuccess(this.booking);
  @override
  List<Object?> get props => [booking];
}

class PaymentVerifiedSuccess extends PaymentState {
  final BookingEntity booking;
  const PaymentVerifiedSuccess(this.booking);
  @override
  List<Object?> get props => [booking];
}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
  @override
  List<Object?> get props => [message];
}

class PaymentCubit extends Cubit<PaymentState> {
  final CPanelStorageClient storageClient;
  final BookingRepository bookingRepository;

  PaymentCubit({
    required this.storageClient,
    required this.bookingRepository,
  }) : super(const PaymentInitial());

  Future<void> submitPaymentProof({
    required String bookingId,
    required String customerUid,
    File? receiptScreenshot,
    required String transactionId,
  }) async {
    emit(const PaymentUploading());
    try {
      String fileKey = 'payments/${customerUid}_$bookingId.jpg';
      if (receiptScreenshot != null && receiptScreenshot.existsSync()) {
        fileKey = await storageClient.uploadFile(
          file: receiptScreenshot,
          userUid: customerUid,
          folder: 'payments',
        );
      }

      final updated = await bookingRepository.updatePaymentProof(
        bookingId: bookingId,
        paymentProofUrl: fileKey,
        transactionId: transactionId,
      );

      emit(PaymentSubmittedSuccess(updated));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> verifyOwnerPayment({
    required String bookingId,
    required int advanceAmount,
  }) async {
    emit(const PaymentUploading());
    try {
      final updated = await bookingRepository.verifyPayment(
        bookingId: bookingId,
        advanceAmount: advanceAmount,
      );
      emit(PaymentVerifiedSuccess(updated));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
