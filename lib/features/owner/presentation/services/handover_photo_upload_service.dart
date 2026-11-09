import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/queued_upload.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';

/// Uploads one handover / return / damage photo to cPanel, folder
/// `handovers`, and returns its signed URL.
///
/// This is the same upload path the vehicle flow uses — direct
/// upload via [uploadOrQueue] ([CPanelStorageClient.uploadFile]),
/// queued into the shared [OfflineSyncQueue] on failure so the file
/// is never lost and the real URL lands on the target doc when the
/// device is back online. Only the folder and the target collection
/// differ from the vehicle flow (`vehicles` → `handovers` /
/// `return_damage_reports`); no new upload path is invented. A null
/// return means "not uploaded yet" — never a fake or local-path URL
/// stored as if it were one (the caller keeps the local path only
/// for the on-screen preview).
class HandoverPhotoUploadService {
  static Future<String?> uploadHandoverPhoto({
    required String shopId,
    required String bookingId,
    required XFile? photo,
    required String targetField,
    String targetCollection = 'handovers',
    OfflineSyncQueue? syncQueue,
  }) async {
    if (photo == null) return null;
    try {
      final cpanel = sl<CPanelStorageClient>();
      final queue = syncQueue ??
          (sl.isRegistered<OfflineSyncQueue>() ? sl<OfflineSyncQueue>() : null);
      if (queue != null) {
        return await uploadOrQueue(
          client: cpanel,
          file: File(photo.path),
          userUid: shopId,
          folder: 'handovers',
          queue: queue,
          targetCollection: targetCollection,
          targetDocId: bookingId,
          targetField: targetField,
        );
      }
      final key = await cpanel.uploadFile(
        file: File(photo.path),
        userUid: shopId,
        folder: 'handovers',
      );
      return cpanel.getSignedMediaUrl(key, shopId);
    } catch (_) {
      return null;
    }
  }
}

/// Itemized return records, scoped by booking id, in Firestore.
///
/// Two small collections — `return_damage_reports` (one doc per
/// damage report: photo, description, repair cost, deduct flag) and
/// `return_extra_charges` (one doc per added charge) — plus the
/// `return_settlements/{bookingId}` doc the settlement service
/// writes at finalize (condition, return photos, payment received).
/// Firestore resolves lazily: without it the service answers with
/// empty lists / no-ops instead of crashing, and nothing is ever
/// written to a local-only shadow that could diverge.
class ReturnRecordsService {
  final FirebaseFirestore? _firestore;

  ReturnRecordsService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<String?> saveDamageReport({
    required String bookingId,
    required String shopId,
    String? photoUrl,
    required String description,
    required int repairCost,
    required bool deductFromDeposit,
  }) async {
    final fs = _resolvedFirestore;
    if (fs == null) return null;
    try {
      final ref = await fs.collection('return_damage_reports').add({
        'bookingId': bookingId,
        'shopId': shopId,
        'photoUrl': photoUrl,
        'description': description,
        'repairCost': repairCost,
        'deductFromDeposit': deductFromDeposit,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<String?> saveExtraCharge({
    required String bookingId,
    required String shopId,
    required String chargeType,
    required int amount,
    required String remarks,
  }) async {
    final fs = _resolvedFirestore;
    if (fs == null) return null;
    try {
      final ref = await fs.collection('return_extra_charges').add({
        'bookingId': bookingId,
        'shopId': shopId,
        'chargeType': chargeType,
        'amount': amount,
        'remarks': remarks,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadDamageReports(
      String bookingId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return const [];
    try {
      final snap = await fs
          .collection('return_damage_reports')
          .where('bookingId', isEqualTo: bookingId)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> loadExtraCharges(
      String bookingId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return const [];
    try {
      final snap = await fs
          .collection('return_extra_charges')
          .where('bookingId', isEqualTo: bookingId)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Totals the return view folds into the settlement: damage the
  /// owner marked "deduct from deposit", and every manually added
  /// extra charge. Both are 0 when nothing was recorded.
  Future<({int deductibleDamage, int extraCharges})> loadTotals(
      String bookingId) async {
    final reports = await loadDamageReports(bookingId);
    var deductibleDamage = 0;
    for (final report in reports) {
      if (report['deductFromDeposit'] == true) {
        deductibleDamage += (report['repairCost'] as num?)?.toInt() ?? 0;
      }
    }
    final charges = await loadExtraCharges(bookingId);
    var extraCharges = 0;
    for (final charge in charges) {
      extraCharges += (charge['amount'] as num?)?.toInt() ?? 0;
    }
    return (
      deductibleDamage: deductibleDamage,
      extraCharges: extraCharges,
    );
  }
}
