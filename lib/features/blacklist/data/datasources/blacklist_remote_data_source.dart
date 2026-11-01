import '../../domain/entities/blacklist_entity.dart';

class BlacklistRemoteDataSource {
  final Map<String, BlacklistEntity> _records = {};
  final Set<String> _blacklistedCnics = {};

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
    return _blacklistedCnics.contains(cnicNumber);
  }
}

