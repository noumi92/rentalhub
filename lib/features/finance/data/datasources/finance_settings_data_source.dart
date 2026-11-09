import 'package:cloud_firestore/cloud_firestore.dart';

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
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final doc =
            await fs.collection('finance_settings').doc(shopId).get();
        final data = doc.data();
        if (data != null) {
          _inMemory = FinanceSettingsModel.fromMap(data);
          return _inMemory!;
        }
      } catch (_) {}
    }
    return _inMemory ?? FinanceSettingsEntity(shopId: shopId);
  }

  Future<void> saveSettings(FinanceSettingsEntity settings) async {
    _inMemory = FinanceSettingsModel.fromEntity(settings);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs
            .collection('finance_settings')
            .doc(settings.shopId)
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
