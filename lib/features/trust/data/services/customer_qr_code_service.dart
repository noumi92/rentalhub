import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../models/customer_qr_code_model.dart';

/// Writes (and, for the admin panel, reads) the restricted CNIC QR
/// number document `customer_qr_codes/{customerId}`.
///
/// The write is best-effort and never throws: when the device is
/// offline the write is queued through [OfflineSyncQueue] (same
/// `firestore_set` kind the KYC record uses) so the number is not
/// lost; when there is no queue it simply reports false. Callers
/// must never fail a customer/KYC save because this write failed —
/// the number is secondary to the record itself.
class CustomerQrCodeService {
  final OfflineSyncQueue? syncQueue;

  CustomerQrCodeService({this.syncQueue});

  /// Returns true when the number was written live, false when it
  /// was queued or could not be written at all.
  Future<bool> saveQrCode({
    required String customerId,
    required String qrCode,
  }) async {
    final code = qrCode.trim();
    if (customerId.isEmpty || code.isEmpty) return false;
    final fields =
        CustomerQrCodeModel(customerId: customerId, qrCode: code).toMap();
    try {
      await FirebaseFirestore.instance
          .collection(CustomerQrCodeModel.collection)
          .doc(customerId)
          .set(
        {
          ...fields,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint('QR code save failed: $e');
      final queue = syncQueue;
      if (queue == null) return false;
      try {
        await queue.enqueue(
          kind: 'firestore_set',
          entityId: customerId,
          payload: {
            'collection': CustomerQrCodeModel.collection,
            'docId': customerId,
            'fields': fields,
          },
        );
      } catch (_) {
        return false;
      }
      return false;
    }
  }

  /// Super-admin read path — the rules deny anyone else, and a denied
  /// or missing doc reads as null, never an exception.
  Future<String?> getQrCode(String customerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(CustomerQrCodeModel.collection)
          .doc(customerId)
          .get();
      final data = doc.data();
      if (data == null) return null;
      final code =
          CustomerQrCodeModel.fromMap(data, doc.id).qrCode;
      return code.isEmpty ? null : code;
    } catch (_) {
      return null;
    }
  }
}
