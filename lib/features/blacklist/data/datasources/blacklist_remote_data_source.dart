import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/blacklist_entity.dart';
import '../models/blacklist_model.dart';

/// Phase B (C4): the shared blacklist, from Firestore with an
/// in-memory fallback for records reported in this session.
///
/// Admin audit (2026-11-14, F-M1): there used to be a hardcoded
/// sample record (BLK-1001, CNIC 35201-9999999-1) seeded into every
/// instance, and `_readAll` fell back to it whenever the collection
/// was empty or unreachable — so the tribunal showed a fake case on
/// a fresh platform and the booking-time check refused that CNIC.
/// The fixture is gone: it belongs in tests, not production code.
/// `_readAll` returns `[]` when the collection is empty or the
/// Firestore read fails; a CNIC is blacklisted only when a real
/// record says so.
class BlacklistRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final Map<String, BlacklistEntity> _records = {};
  static int _idSeq = 0;

  BlacklistRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

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
        return snap.docs
            .map((d) => BlacklistModel.fromMap(d.data(), d.id))
            .toList();
      } catch (_) {
        return [];
      }
    }
    // No Firestore (unit tests / Firebase not initialised): only the
    // records reported in this session exist — never a seeded sample.
    return _records.values.toList();
  }

  /// Strict read for the admin tribunal: throws when Firestore is
  /// available but the read fails, so an outage shows the error
  /// state instead of an empty tribunal (F-M6). Returns `[]` when
  /// the collection is empty. With no Firestore, returns the
  /// session's reported records.
  Future<List<BlacklistEntity>> getAllRecordsStrict() async {
    final fs = _resolvedFirestore;
    if (fs == null) return _records.values.toList();
    final snap = await fs.collection('blacklist').get();
    return snap.docs
        .map((d) => BlacklistModel.fromMap(d.data(), d.id))
        .toList();
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

    // The Firestore write goes first: a failed write throws instead
    // of leaving a record that only exists in this session's memory
    // (F-M6 — the caller must not claim a report that never landed).
    final fs = _resolvedFirestore;
    if (fs != null) {
      await fs
          .collection('blacklist')
          .doc(id)
          .set(BlacklistModel.fromEntity(entity).toMap());
    }
    _records[id] = entity;
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

    // Same rule as the report path: the Firestore write goes first
    // and a failed write throws — a revert that only lived in memory
    // would leave the flag active everywhere else.
    final fs = _resolvedFirestore;
    if (fs != null) {
      await fs
          .collection('blacklist')
          .doc(blacklistId)
          .set(BlacklistModel.fromEntity(reverted).toMap());
    }
    _records[blacklistId] = reverted;
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
