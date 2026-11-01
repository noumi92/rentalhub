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
  });

  BlacklistEntity copyWith({
    bool? isActive,
    String? revertedByAdmin,
    String? revertedReason,
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
      ];
}

