import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/shop_id_resolution.dart';
import '../../domain/entities/booking_settings_entity.dart';
import '../models/booking_settings_model.dart';

/// Worker A (2026-11-21): the shop's booking settings, one document
/// `booking_settings/{shopId}`, Firestore-first with an in-memory
/// fallback — the same shape as [FinanceSettingsDataSource]. A
/// missing document reads as the defaults (no driver rate set, so
/// trips with a driver add no extra charge).
class BookingSettingsDataSource {
  final FirebaseFirestore? _firestore;
  BookingSettingsModel? _inMemory;

  BookingSettingsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<BookingSettingsEntity> getSettings(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final canonical = await canonicalShopId(fs, shopId);
        var doc = await fs
            .collection('booking_settings')
            .doc(canonical)
            .get();
        var data = doc.data();
        if (data == null && canonical != shopId) {
          doc = await fs.collection('booking_settings').doc(shopId).get();
          data = doc.data();
        }
        if (data != null) {
          _inMemory = BookingSettingsModel.fromMap(data);
          return _inMemory!;
        }
      } catch (_) {}
    }
    return _inMemory ?? BookingSettingsEntity(shopId: shopId);
  }

  Future<void> saveSettings(BookingSettingsEntity settings) async {
    final fs = _resolvedFirestore;
    final canonical = await canonicalShopId(fs, settings.shopId);
    _inMemory = BookingSettingsModel.fromEntity(
        settings.copyWith(shopId: canonical));
    if (fs != null) {
      try {
        await fs
            .collection('booking_settings')
            .doc(canonical)
            .set(
              {
                ..._inMemory!.toMap(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
      } catch (_) {}
    }
  }
}
