import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/queued_upload.dart';
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

  /// Phase B (B3): the persisted pending-write store. When set, a
  /// failed receipt upload is queued instead of failing the
  /// submission — the proof is recorded with its TID and the image
  /// follows on sync.
  final OfflineSyncQueue? syncQueue;

  PaymentCubit({
    required this.storageClient,
    required this.bookingRepository,
    this.syncQueue,
  }) : super(const PaymentInitial());

  Future<void> submitPaymentProof({
    required String bookingId,
    required String customerUid,
    File? receiptScreenshot,
    required String transactionId,
  }) async {
    emit(const PaymentUploading());
    try {
      // Item 8: what lands in `bookings/{id}.paymentProofUrl` must
      // be a viewable URL, not the bare storage key. The live
      // upload path (PaymentProofUploadService) stores the signed
      // media.php URL; this cubit stored the bare key
      // (`payments/<file>`) and the owner view passes the stored
      // value straight to Image.network, so a proof filed here
      // could never display. Sign it the same way.
      String proofUrl = '';
      if (receiptScreenshot != null && receiptScreenshot.existsSync()) {
        try {
          final fileKey = await storageClient.uploadFile(
            file: receiptScreenshot,
            userUid: customerUid,
            folder: 'payments',
          );
          proofUrl = storageClient.getSignedMediaUrl(fileKey, customerUid);
        } catch (_) {
          final queue = syncQueue;
          if (queue == null) rethrow;
          await enqueueUpload(
            file: receiptScreenshot,
            userUid: customerUid,
            folder: 'payments',
            queue: queue,
            targetCollection: 'bookings',
            targetDocId: bookingId,
            targetField: 'paymentProofUrl',
            extra: {
              'status': 'payment_submitted',
              'transactionId': transactionId,
            },
          );
          proofUrl = '';
        }
      }

      final updated = await bookingRepository.updatePaymentProof(
        bookingId: bookingId,
        paymentProofUrl: proofUrl,
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
