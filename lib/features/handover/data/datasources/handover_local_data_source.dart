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
            customerSignatureSvg: d['customer_signature'],
            ownerSignatureSvg: d['owner_signature'],
            agreementPdfUrl: d['agreement_pdf_url'],
            isSynced: false,
          ),
        );
      }
    }
    return pending;
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

