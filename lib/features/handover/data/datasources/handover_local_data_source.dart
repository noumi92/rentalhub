import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/handover_entity.dart';

class HandoverLocalDataSource {
  final SharedPreferences prefs;

  static const String _handoverBoxKey = 'offline_handovers_box';
  static const String _syncQueueKey = 'offline_sync_queue';

  HandoverLocalDataSource({required this.prefs});

  Future<void> saveHandoverOffline(HandoverEntity handover) async {
    final existingJson = prefs.getString(_handoverBoxKey);
    final Map<String, dynamic> map = existingJson != null
        ? Map<String, dynamic>.from(jsonDecode(existingJson))
        : {};

    map[handover.bookingId] = {
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
      'customer_name': handover.customerName,
      'cnic': handover.cnicNumber,
      'vehicle_details': handover.vehicleDetails,
      'total_amount': handover.totalAmount,
      'agreement_pdf_url': handover.agreementPdfUrl,
      'is_synced': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_handoverBoxKey, jsonEncode(map));

    final List<String> queue = prefs.getStringList(_syncQueueKey) ?? [];
    if (!queue.contains(handover.bookingId)) {
      queue.add(handover.bookingId);
      await prefs.setStringList(_syncQueueKey, queue);
    }
  }

  Future<List<HandoverEntity>> getPendingSyncHandovers() async {
    final existingJson = prefs.getString(_handoverBoxKey);
    if (existingJson == null) return [];
    final Map<String, dynamic> map =
        Map<String, dynamic>.from(jsonDecode(existingJson));
    final List<HandoverEntity> pending = [];

    for (final entry in map.entries) {
      final d = Map<String, dynamic>.from(entry.value);
      if (d['is_synced'] == false) {
        pending.add(
          HandoverEntity(
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
            customerName: d['customer_name'],
            cnicNumber: d['cnic'],
            vehicleDetails: d['vehicle_details'],
            totalAmount: d['total_amount'],
            agreementPdfUrl: d['agreement_pdf_url'],
            isSynced: false,
          ),
        );
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
    final d = Map<String, dynamic>.from(raw);
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
      customerName: d['customer_name'],
      cnicNumber: d['cnic'],
      vehicleDetails: d['vehicle_details'],
      totalAmount: d['total_amount'],
      agreementPdfUrl: d['agreement_pdf_url'],
      isSynced: d['is_synced'] == true,
    );
  }

  Future<void> markSynced(String bookingId, String agreementPdfUrl) async {
    final existingJson = prefs.getString(_handoverBoxKey);
    if (existingJson == null) return;
    final Map<String, dynamic> map =
        Map<String, dynamic>.from(jsonDecode(existingJson));
    if (map.containsKey(bookingId)) {
      final item = Map<String, dynamic>.from(map[bookingId]);
      item['is_synced'] = true;
      item['agreement_pdf_url'] = agreementPdfUrl;
      map[bookingId] = item;
      await prefs.setString(_handoverBoxKey, jsonEncode(map));
    }

    final List<String> queue = prefs.getStringList(_syncQueueKey) ?? [];
    queue.remove(bookingId);
    await prefs.setStringList(_syncQueueKey, queue);
  }
}

