import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/shop_id_resolution.dart';
import '../../domain/entities/finance_settings_entity.dart';
import '../models/finance_settings_model.dart';

/// Audit impl (O48): the shop's finance settings, one document
/// `finance_settings/{shopId}`, Firestore-first with an in-memory
/// fallback. A missing document reads as the defaults (PKR, no tax
/// or service charge, Cash + Bank Transfer on, receipt off).
class FinanceSettingsDataSource {
  final FirebaseFirestore? _firestore;
  FinanceSettingsModel? _inMemory;

  FinanceSettingsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<FinanceSettingsEntity> getSettings(String shopId) async {
    // Shop-id linking (2026-11-15): the settings document is keyed
    // by the canonical shop doc id; a legacy bare-UID document is
    // still honoured as a fallback.
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final canonical = await canonicalShopId(fs, shopId);
        var doc = await fs
            .collection('finance_settings')
            .doc(canonical)
            .get();
        var data = doc.data();
        if (data == null && canonical != shopId) {
          doc = await fs.collection('finance_settings').doc(shopId).get();
          data = doc.data();
        }
        if (data != null) {
          _inMemory = FinanceSettingsModel.fromMap(data);
          return _inMemory!;
        }
      } catch (_) {}
    }
    return _inMemory ?? FinanceSettingsEntity(shopId: shopId);
  }

  Future<void> saveSettings(FinanceSettingsEntity settings) async {
    final fs = _resolvedFirestore;
    final canonical =
        await canonicalShopId(fs, settings.shopId);
    _inMemory = FinanceSettingsModel.fromEntity(
        settings.copyWith(shopId: canonical));
    if (fs != null) {
      try {
        await fs
            .collection('finance_settings')
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
