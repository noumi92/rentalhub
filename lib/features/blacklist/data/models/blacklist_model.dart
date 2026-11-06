import '../../domain/entities/blacklist_entity.dart';

class BlacklistModel extends BlacklistEntity {
  const BlacklistModel({
    required super.blacklistId,
    required super.reportedByShopId,
    required super.cnicNumber,
    required super.phoneNumber,
    required super.reasonCategory,
    required super.description,
    super.evidenceUrls,
    super.isActive,
    super.revertedByAdmin,
    super.revertedReason,
    super.reportedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'blacklistId': blacklistId,
      'reportedByShopId': reportedByShopId,
      'cnicNumber': cnicNumber,
      'phoneNumber': phoneNumber,
      'reasonCategory': reasonCategory,
      'description': description,
      'evidenceUrls': evidenceUrls,
      'isActive': isActive,
      if (revertedByAdmin != null) 'revertedByAdmin': revertedByAdmin,
      if (revertedReason != null) 'revertedReason': revertedReason,
      if (reportedAt != null)
        'reportedAt': reportedAt!.toIso8601String(),
    };
  }

  factory BlacklistModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return BlacklistModel(
      blacklistId: id ?? (map['blacklistId'] as String? ?? ''),
      reportedByShopId: (map['reportedByShopId'] as String?) ?? '',
      cnicNumber: (map['cnicNumber'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      reasonCategory: (map['reasonCategory'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      evidenceUrls: (map['evidenceUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isActive: (map['isActive'] as bool?) ?? true,
      revertedByAdmin: map['revertedByAdmin'] as String?,
      revertedReason: map['revertedReason'] as String?,
      reportedAt: map['reportedAt'] != null
          ? DateTime.tryParse(map['reportedAt'].toString())
          : null,
    );
  }

  factory BlacklistModel.fromEntity(BlacklistEntity entity) {
    return BlacklistModel(
      blacklistId: entity.blacklistId,
      reportedByShopId: entity.reportedByShopId,
      cnicNumber: entity.cnicNumber,
      phoneNumber: entity.phoneNumber,
      reasonCategory: entity.reasonCategory,
      description: entity.description,
      evidenceUrls: entity.evidenceUrls,
      isActive: entity.isActive,
      revertedByAdmin: entity.revertedByAdmin,
      revertedReason: entity.revertedReason,
      reportedAt: entity.reportedAt,
    );
  }
}
