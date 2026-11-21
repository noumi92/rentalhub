import 'dart:io';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/queued_upload.dart';
import '../../../../core/network/cpanel_storage_client.dart';

/// Outcome of a payment-proof upload attempt (Item 8).
enum PaymentProofUploadStatus {
  /// A real cPanel URL is in hand — the booking may be marked
  /// `payment_submitted`.
  uploaded,

  /// The upload failed but the receipt is queued: the queue drain
  /// writes the real URL + `payment_submitted` when back online.
  /// The booking must NOT be marked submitted yet.
  queued,

  /// Nothing uploaded and nothing queued — the customer must retry.
  failed,
}

/// The payment-proof upload, on the same path as the vehicle /
/// handover photo uploads: [uploadOrQueue] tries the cPanel upload
/// and, on failure, queues the file so the queue drain writes the
/// real URL into `bookings/{bookingId}.paymentProofUrl` (plus
/// `status` + `transactionId`) when the device is back online. It
/// returns null when nothing was uploaded — never a fake URL.
///
/// Next-step batch (2026-11-21): [bookingStatus] is the booking's
/// status as the caller knows it. When it is already past payment
/// (`paid` / `active` / `completed` / `cancelled`) the upload is
/// refused WITHOUT uploading or queueing anything — a queued
/// receipt would re-file `status: payment_submitted` on drain and
/// downgrade a paid booking. The data source hard-rejects the same
/// four statuses as a backstop.
///
/// userUid stays the customer id: `generateAuthToken` ignores it
/// (the digest is HMAC(timestamp) only) and `uploadFile` never
/// sends it as a field — only the Bearer token, `category` and the
/// file — so the server cannot key path/auth off it, and the
/// customer-side uploads (KYC docs, PaymentCubit proof) all use the
/// customer UID while owner-side uploads use the shop UID. The
/// `payments` folder itself is a server question: upload.php is
/// not in this repo.
class PaymentProofUploadService {
  static Future<({PaymentProofUploadStatus status, String? proofUrl})>
      uploadProof({
    required CPanelStorageClient client,
    required File file,
    required String customerId,
    required String bookingId,
    required String transactionId,
    OfflineSyncQueue? queue,
    // Next-step batch (2026-11-21): the booking's status as the
    // caller knows it — see the class doc. Null means unknown, in
    // which case the upload proceeds and the data source remains
    // the backstop.
    String? bookingStatus,
  }) async {
    // Past payment: refuse before any upload or queue entry.
    if (bookingStatus != null &&
        const {'paid', 'active', 'completed', 'cancelled'}
            .contains(bookingStatus)) {
      return (status: PaymentProofUploadStatus.failed, proofUrl: null);
    }
    String? proofUrl;
    if (queue != null) {
      proofUrl = await uploadOrQueue(
        client: client,
        file: file,
        userUid: customerId,
        folder: 'payments',
        queue: queue,
        targetCollection: 'bookings',
        targetDocId: bookingId,
        targetField: 'paymentProofUrl',
        // The drain writes these into the booking doc alongside
        // the URL; proofSubmittedAt matches what updatePaymentProof
        // stamps (ISO string), so a proof that lands via the queue
        // still carries its submission time for the O19 view.
        extra: {'status': 'payment_submitted', 'transactionId': transactionId, 'proofSubmittedAt': DateTime.now().toIso8601String()},
      );
    } else {
      // No queue (the same direct fallback as the vehicle path):
      // a failed upload is a failure, never a local path filed
      // as proof.
      try {
        final key = await client.uploadFile(
          file: file,
          userUid: customerId,
          folder: 'payments',
        );
        proofUrl = client.getSignedMediaUrl(key, customerId);
      } catch (_) {
        proofUrl = null;
      }
    }
    if (proofUrl != null && proofUrl.isNotEmpty) {
      return (status: PaymentProofUploadStatus.uploaded, proofUrl: proofUrl);
    }
    if (queue != null && await _isQueued(queue, bookingId)) {
      return (status: PaymentProofUploadStatus.queued, proofUrl: null);
    }
    return (status: PaymentProofUploadStatus.failed, proofUrl: null);
  }

  /// Whether the failed upload was queued for retry — the
  /// `upload:{bookingId}:paymentProofUrl` entry [uploadOrQueue]
  /// enqueues — as opposed to failing to queue at all.
  static Future<bool> _isQueued(
      OfflineSyncQueue queue, String bookingId) async {
    final entries = await queue.pendingEntries();
    return entries.any((e) =>
        e.kind == 'upload' &&
        e.payload['targetDocId'] == bookingId &&
        e.payload['targetField'] == 'paymentProofUrl');
  }
}
