import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/blacklist_entity.dart';
import '../models/blacklist_model.dart';

/// Phase B (C4): the shared blacklist, from Firestore with an
/// in-memory fallback. Before this phase the whole feature lived in
/// memory with one hardcoded sample record — reports were lost on
/// every restart and never reached other shops. The sample record
/// now only seeds the offline fallback.
class BlacklistRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final Map<String, BlacklistEntity> _records = {};
  final Set<String> _blacklistedCnics = {};
  static int _idSeq = 0;

  BlacklistRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore {
    _initSampleData();
  }

  void _initSampleData() {
    const defaultBlacklisted = BlacklistEntity(
      blacklistId: 'BLK-1001',
      reportedByShopId: 'shop-metro-lahore',
      cnicNumber: '35201-9999999-1',
      phoneNumber: '0300-9998888',
      reasonCategory: 'Default & Car Impoundment',
      description:
          'Customer failed to return Corolla Altis after 14 days, vehicle tracked and recovered from police impound.',
      isActive: true,
    );
    _records[defaultBlacklisted.blacklistId] = defaultBlacklisted;
    _blacklistedCnics.add(defaultBlacklisted.cnicNumber);
  }

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<List<BlacklistEntity>> _readAll() async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs.collection('blacklist').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => BlacklistModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _records.values.toList();
  }

  Future<BlacklistEntity> reportCustomerToBlacklist({
    required String reportedByShopId,
    required String cnicNumber,
    required String phoneNumber,
    required String reasonCategory,
    required String description,
    List<String> evidenceUrls = const [],
  }) async {
    final id =
        'BLK-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';
    final entity = BlacklistEntity(
      blacklistId: id,
      reportedByShopId: reportedByShopId,
      cnicNumber: cnicNumber,
      phoneNumber: phoneNumber,
      reasonCategory: reasonCategory,
      description: description,
      evidenceUrls: evidenceUrls,
      isActive: true,
      reportedAt: DateTime.now(),
    );
    _records[id] = entity;
    _blacklistedCnics.add(cnicNumber);

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs
            .collection('blacklist')
            .doc(id)
            .set(BlacklistModel.fromEntity(entity).toMap());
      } catch (_) {}
    }
    return entity;
  }

  Future<BlacklistEntity> revertBlacklistRecord({
    required String blacklistId,
    required String adminUid,
    required String justification,
  }) async {
    if (justification.trim().isEmpty) {
      throw ArgumentError('Mandatory audit justification is required.');
    }
    final existing = await _findById(blacklistId);
    if (existing == null) {
      throw Exception('Blacklist record not found: $blacklistId');
    }
    final reverted = existing.copyWith(
      isActive: false,
      revertedByAdmin: adminUid,
      revertedReason: justification.trim(),
    );
    _records[blacklistId] = reverted;
    _blacklistedCnics.remove(existing.cnicNumber);

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs
            .collection('blacklist')
            .doc(blacklistId)
            .set(BlacklistModel.fromEntity(reverted).toMap());
      } catch (_) {}
    }
    return reverted;
  }

  Future<BlacklistEntity?> _findById(String blacklistId) async {
    final all = await _readAll();
    for (final entity in all) {
      if (entity.blacklistId == blacklistId) return entity;
    }
    return null;
  }

  Future<bool> isCnicBlacklisted(String cnicNumber) async {
    final clean = cnicNumber.replaceAll('-', '').trim();
    final all = await _readAll();
    return all.any((c) =>
        c.isActive &&
        c.cnicNumber.replaceAll('-', '').trim() == clean);
  }

  Future<BlacklistEntity?> getBlacklistRecordByCnic(
      String cnicNumber) async {
    final clean = cnicNumber.replaceAll('-', '').trim();
    final all = await _readAll();
    for (final entity in all) {
      if (entity.cnicNumber.replaceAll('-', '').trim() == clean &&
          entity.isActive) {
        return entity;
      }
    }
    return null;
  }

  Future<List<BlacklistEntity>> getAllRecords() async => _readAll();

  /// Admin-integration audit (2026-11-10): file an appeal against a
  /// blacklist record. Before this, `appeal_status` was only ever
  /// written by the admin tribunal decision ('kept' / 'removed') —
  /// nothing in the app could file an appeal, so the tribunal could
  /// only decide appeals that could never exist. This writes
  /// `appeal_status: 'pending'` + the reason on the `blacklist`
  /// document the tribunal reads; the record stays active until the
  /// tribunal decides. Returns false when the write failed (the
  /// caller must not claim an appeal was filed). The in-memory copy
  /// carries no appeal fields — the appeal state lives on the
  /// document, read by AdminPeopleDataSource.getBlacklistRecords.
  Future<bool> submitAppeal({
    required String blacklistId,
    required String reason,
  }) async {
    if (blacklistId.isEmpty || reason.trim().isEmpty) return false;
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      await fs.collection('blacklist').doc(blacklistId).update({
        'appeal_status': 'pending',
        'appeal_reason': reason.trim(),
        'appeal_filed_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Phase B (C4): the reports this shop filed, newest first.
  Future<List<BlacklistEntity>> getShopReports(String shopId) async {
    final all = await _readAll();
    final mine =
        all.where((r) => r.reportedByShopId == shopId).toList();
    mine.sort((a, b) => (b.reportedAt ?? DateTime(2000))
        .compareTo(a.reportedAt ?? DateTime(2000)));
    return mine;
  }
}
