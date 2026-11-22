import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../domain/entities/handover_entity.dart';

/// Phase B (B3): the offline handover store, rebuilt on the shared
/// sync queue.
///
/// The box (`offline_handovers_box`) is still the local record — the
/// handover screen reads it even when the booking was opened from a
/// deep link. But the *queue* is now the shared [OfflineSyncQueue]:
/// saving a handover enqueues a `'handover'` entry (kind +
/// bookingId + the handover JSON), and the sync engine drains it.
/// The old private `_syncQueueKey` list is gone — one queue for
/// every write path, drained automatically on reconnect (B2).
class HandoverLocalDataSource {
  final SharedPreferences prefs;
  final OfflineSyncQueue syncQueue;

  static const String _handoverBoxKey = 'offline_handovers_box';

  HandoverLocalDataSource({
    required this.prefs,
    OfflineSyncQueue? syncQueue,
  }) : syncQueue = syncQueue ?? OfflineSyncQueue(prefs: prefs);

  Map<String, dynamic> _handoverMap(HandoverEntity handover) => {
        'booking_id': handover.bookingId,
        'odometer': handover.initialOdometer,
        'fuel_level': handover.fuelLevel,
        'damage_notes': handover.damageNotes,
        'customer_signature': handover.customerSignatureSvg,
        'owner_signature': handover.ownerSignatureSvg,
        'customer_signature_b64': handover.customerSignatureB64,
        'owner_signature_b64': handover.ownerSignatureB64,
        'agreement_pdf_b64': handover.agreementPdfB64,
        'shop_id': handover.shopId,
        'shop_name': handover.shopName,
        'customer_id': handover.customerId,
        'customer_name': handover.customerName,
        'cnic': handover.cnicNumber,
        'vehicle_details': handover.vehicleDetails,
        'total_amount': handover.totalAmount,
        // Audit 2026-11-15 PW-16: the handover balance rides the
        // offline queue with the record (old records lack the keys
        // and read back as null).
        'balance_due_pkr': handover.balanceDuePkr,
        'balance_payment_method': handover.balancePaymentMethod,
        // Financial audit (2026-11-20): whether the balance was
        // actually received — without it the offline record cannot
        // tell a collected balance from an uncollected one.
        'balance_received': handover.balanceReceived,
        'photo_front_url': handover.photoFrontUrl,
        'photo_back_url': handover.photoBackUrl,
        'photo_left_url': handover.photoLeftUrl,
        'photo_right_url': handover.photoRightUrl,
        'documents_given': handover.documentsGiven,
        'accessories': handover.accessories,
        'keys_handed_over': handover.keysHandedOver,
        // Item 9 (O26–O30): the wizard's new fields ride the offline
        // queue with the record (old records lack the keys and read
        // back as null / false / empty).
        'face_check_confirmed': handover.faceCheckConfirmed,
        'face_checked_at': handover.faceCheckedAt?.toIso8601String(),
        'deposit_payment_method': handover.depositPaymentMethod,
        'deposit_received_at':
            handover.depositReceivedAt?.toIso8601String(),
        'receipt_id': handover.receiptId,
        'ac_working': handover.acWorking,
        'lights_working': handover.lightsWorking,
        'photo_interior_url': handover.photoInteriorUrl,
        'photo_dashboard_url': handover.photoDashboardUrl,
        'photo_taken_at': handover.photoTakenAt,
        'damage_pins':
            handover.damagePins.map((p) => p.toJson()).toList(),
        'trip_start_at': handover.tripStartAt?.toIso8601String(),
        'wizard_completed_at':
            handover.wizardCompletedAt?.toIso8601String(),
        'customer_signature_source': handover.customerSignatureSource,
        'owner_signature_source': handover.ownerSignatureSource,
        'agreement_pdf_url': handover.agreementPdfUrl,
        'is_synced': false,
        'created_at': DateTime.now().toIso8601String(),
      };

  HandoverEntity _entityFromMap(Map<String, dynamic> d) {
    return HandoverEntity(
      bookingId: d['booking_id'],
      initialOdometer: d['odometer'],
      fuelLevel: d['fuel_level'],
      damageNotes: List<String>.from(d['damage_notes'] ?? []),
      customerSignatureSvg: d['customer_signature'] ?? '',
      ownerSignatureSvg: d['owner_signature'] ?? '',
      customerSignatureB64: d['customer_signature_b64'],
      ownerSignatureB64: d['owner_signature_b64'],
      agreementPdfB64: d['agreement_pdf_b64'],
      shopId: d['shop_id'],
      shopName: d['shop_name'],
      customerId: d['customer_id'],
      customerName: d['customer_name'],
      cnicNumber: d['cnic'],
      vehicleDetails: d['vehicle_details'],
      totalAmount: d['total_amount'],
      balanceDuePkr: (d['balance_due_pkr'] as num?)?.toInt(),
      balancePaymentMethod: d['balance_payment_method'] as String?,
      balanceReceived: d['balance_received'] as bool?,
      photoFrontUrl: d['photo_front_url'] as String?,
      photoBackUrl: d['photo_back_url'] as String?,
      photoLeftUrl: d['photo_left_url'] as String?,
      photoRightUrl: d['photo_right_url'] as String?,
      documentsGiven: List<String>.from(d['documents_given'] ?? []),
      accessories: List<String>.from(d['accessories'] ?? []),
      keysHandedOver: d['keys_handed_over'] == true,
      faceCheckConfirmed: d['face_check_confirmed'] == true,
      faceCheckedAt: _parseDate(d['face_checked_at']),
      depositPaymentMethod: d['deposit_payment_method'] as String?,
      depositReceivedAt: _parseDate(d['deposit_received_at']),
      receiptId: d['receipt_id'] as String?,
      acWorking: d['ac_working'] as bool?,
      lightsWorking: d['lights_working'] as bool?,
      photoInteriorUrl: d['photo_interior_url'] as String?,
      photoDashboardUrl: d['photo_dashboard_url'] as String?,
      photoTakenAt: Map<String, String>.from(
          (d['photo_taken_at'] as Map? ?? {}).map(
              (k, v) => MapEntry(k.toString(), v.toString()))),
      damagePins: (d['damage_pins'] as List? ?? [])
          .map((p) => HandoverDamagePin.fromJson(
              Map<String, dynamic>.from(p as Map)))
          .toList(),
      tripStartAt: _parseDate(d['trip_start_at']),
      wizardCompletedAt: _parseDate(d['wizard_completed_at']),
      customerSignatureSource: d['customer_signature_source'] as String?,
      ownerSignatureSource: d['owner_signature_source'] as String?,
      agreementPdfUrl: d['agreement_pdf_url'],
      isSynced: d['is_synced'] == true,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Future<void> saveHandoverOffline(HandoverEntity handover) async {
    final existingJson = prefs.getString(_handoverBoxKey);
    final Map<String, dynamic> map = existingJson != null
        ? Map<String, dynamic>.from(jsonDecode(existingJson))
        : {};

    map[handover.bookingId] = _handoverMap(handover);
    await prefs.setString(_handoverBoxKey, jsonEncode(map));

    await syncQueue.enqueue(
      kind: 'handover',
      entityId: handover.bookingId,
      payload: Map<String, dynamic>.from(map[handover.bookingId] as Map),
    );
  }

  Future<List<HandoverEntity>> getPendingSyncHandovers() async {
    final entries = await syncQueue.pendingEntries();
    final boxJson = prefs.getString(_handoverBoxKey);
    final Map<String, dynamic> box = boxJson != null
        ? Map<String, dynamic>.from(jsonDecode(boxJson))
        : {};
    final pending = <HandoverEntity>[];
    for (final entry in entries) {
      if (entry.kind != 'handover') continue;
      final raw = box[entry.entityId] ?? entry.payload;
      final d = Map<String, dynamic>.from(raw as Map);
      if (d['is_synced'] == false) {
        pending.add(_entityFromMap(d));
      }
    }
    return pending;
  }

  /// Phase B (E3): the stored handover for one booking, if any —
  /// so the contract screen can show the generated PDF even when
  /// it was opened from a deep link instead of the handover flow.
  Future<HandoverEntity?> getHandover(String bookingId) async {
    final existingJson = prefs.getString(_handoverBoxKey);
    if (existingJson == null) return null;
    final Map<String, dynamic> map =
        Map<String, dynamic>.from(jsonDecode(existingJson));
    final raw = map[bookingId];
    if (raw == null) return null;
    return _entityFromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> markSynced(String bookingId, String agreementPdfUrl) async {
    final existingJson = prefs.getString(_handoverBoxKey);
    if (existingJson != null) {
      final Map<String, dynamic> map =
          Map<String, dynamic>.from(jsonDecode(existingJson));
      if (map.containsKey(bookingId)) {
        final item = Map<String, dynamic>.from(map[bookingId]);
        item['is_synced'] = true;
        item['agreement_pdf_url'] = agreementPdfUrl;
        map[bookingId] = item;
        await prefs.setString(_handoverBoxKey, jsonEncode(map));
      }
    }

    final entries = await syncQueue.entriesForEntity(bookingId);
    for (final entry in entries) {
      if (entry.kind == 'handover') {
        await syncQueue.remove(entry.id);
      }
    }
  }
}

