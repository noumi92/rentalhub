import '../../domain/entities/partner_share_entity.dart';

class PartnerShareModel extends PartnerShareEntity {
  const PartnerShareModel({
    required super.shareId,
    required super.shopId,
    required super.partnerName,
    required super.sharePercent,
    required super.createdAt,
  });

  factory PartnerShareModel.fromEntity(PartnerShareEntity e) {
    return PartnerShareModel(
      shareId: e.shareId,
      shopId: e.shopId,
      partnerName: e.partnerName,
      sharePercent: e.sharePercent,
      createdAt: e.createdAt,
    );
  }

  factory PartnerShareModel.fromMap(Map<String, dynamic> map) {
    return PartnerShareModel(
      shareId: map['shareId'] ?? '',
      shopId: map['shopId'] ?? '',
      partnerName: map['partnerName'] ?? '',
      sharePercent: map['sharePercent'] ?? 0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shareId': shareId,
      'shopId': shopId,
      'partnerName': partnerName,
      'sharePercent': sharePercent,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
