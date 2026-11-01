import '../../domain/entities/blacklist_entity.dart';

class BlacklistRemoteDataSource {
  final Map<String, BlacklistEntity> _records = {};
  final Set<String> _blacklistedCnics = {};

  BlacklistRemoteDataSource() {
    _initSampleData();
  }

  void _initSampleData() {
    const defaultBlacklisted = BlacklistEntity(
      blacklistId: 'BLK-1001',
      reportedByShopId: 'shop-metro-lahore',
      cnicNumber: '35201-9999999-1',
      phoneNumber: '0300-9998888',
      reasonCategory: 'Default & Car Impoundment',
      description: 'Customer failed to return Corolla Altis after 14 days, vehicle tracked and recovered from police impound.',
      isActive: true,
    );
    _records[defaultBlacklisted.blacklistId] = defaultBlacklisted;
    _blacklistedCnics.add(defaultBlacklisted.cnicNumber);
  }

  Future<BlacklistEntity> reportCustomerToBlacklist({
    required String reportedByShopId,
    required String cnicNumber,
    required String phoneNumber,
    required String reasonCategory,
    required String description,
    List<String> evidenceUrls = const [],
  }) async {
    final id = 'BLK-${1001 + _records.length}';
    final entity = BlacklistEntity(
      blacklistId: id,
      reportedByShopId: reportedByShopId,
      cnicNumber: cnicNumber,
      phoneNumber: phoneNumber,
      reasonCategory: reasonCategory,
      description: description,
      evidenceUrls: evidenceUrls,
      isActive: true,
    );
    _records[id] = entity;
    _blacklistedCnics.add(cnicNumber);
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
    final existing = _records[blacklistId];
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
    return reverted;
  }

  Future<bool> isCnicBlacklisted(String cnicNumber) async {
    final clean = cnicNumber.replaceAll('-', '').trim();
    return _blacklistedCnics.any((c) => c.replaceAll('-', '').trim() == clean);
  }

  Future<BlacklistEntity?> getBlacklistRecordByCnic(String cnicNumber) async {
    final clean = cnicNumber.replaceAll('-', '').trim();
    for (final entity in _records.values) {
      if (entity.cnicNumber.replaceAll('-', '').trim() == clean && entity.isActive) {
        return entity;
      }
    }
    return null;
  }

  Future<List<BlacklistEntity>> getAllRecords() async {
    return _records.values.toList();
  }
}

