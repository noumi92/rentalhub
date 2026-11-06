import 'package:equatable/equatable.dart';

class BlacklistEntity extends Equatable {
  final String blacklistId;
  final String reportedByShopId;
  final String cnicNumber;
  final String phoneNumber;
  final String reasonCategory;
  final String description;
  final List<String> evidenceUrls;
  final bool isActive;
  final String? revertedByAdmin;
  final String? revertedReason;

  /// Phase B (C4): when the report was filed.
  final DateTime? reportedAt;

  const BlacklistEntity({
    required this.blacklistId,
    required this.reportedByShopId,
    required this.cnicNumber,
    required this.phoneNumber,
    required this.reasonCategory,
    required this.description,
    this.evidenceUrls = const [],
    this.isActive = true,
    this.revertedByAdmin,
    this.revertedReason,
    this.reportedAt,
  });

  BlacklistEntity copyWith({
    bool? isActive,
    String? revertedByAdmin,
    String? revertedReason,
    DateTime? reportedAt,
  }) {
    return BlacklistEntity(
      blacklistId: blacklistId,
      reportedByShopId: reportedByShopId,
      cnicNumber: cnicNumber,
      phoneNumber: phoneNumber,
      reasonCategory: reasonCategory,
      description: description,
      evidenceUrls: evidenceUrls,
      isActive: isActive ?? this.isActive,
      revertedByAdmin: revertedByAdmin ?? this.revertedByAdmin,
      revertedReason: revertedReason ?? this.revertedReason,
      reportedAt: reportedAt ?? this.reportedAt,
    );
  }

  @override
  List<Object?> get props => [
        blacklistId,
        reportedByShopId,
        cnicNumber,
        phoneNumber,
        reasonCategory,
        description,
        evidenceUrls,
        isActive,
        revertedByAdmin,
        revertedReason,
        reportedAt,
      ];
}

