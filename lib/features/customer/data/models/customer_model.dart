import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.customerId,
    required super.shopId,
    required super.name,
    required super.phone,
    super.cnic,
    super.source,
    required super.createdAt,
    super.dateOfBirth,
    super.cnicExpiry,
    super.fatherName,
    super.address,
    super.profilePhotoUrl,
    super.thumbprintUrl,
    super.leftFingerprintUrl,
    super.rightFingerprintUrl,
    super.cnicFrontUrl,
    super.cnicBackUrl,
    super.licenseNumber,
    super.licenseExpiry,
    super.licenseFrontUrl,
    super.licenseBackUrl,
    super.utilityBillUrl,
    super.extraDocumentUrls,
    super.signatureUrl,
    super.guarantorCustomerId,
    super.guarantorRelation,
    super.approvalStatus,
    super.rejectionReason,
    super.reviewedAt,
    super.pushNotifications,
    super.whatsappNotifications,
    super.savedShopIds,
    super.shopStatuses,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'shopId': shopId,
      'name': name,
      'phone': phone,
      if (cnic != null) 'cnic': cnic,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (cnicExpiry != null) 'cnicExpiry': cnicExpiry,
      if (fatherName != null) 'fatherName': fatherName,
      if (address != null) 'address': address,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (thumbprintUrl != null) 'thumbprintUrl': thumbprintUrl,
      if (leftFingerprintUrl != null)
        'leftFingerprintUrl': leftFingerprintUrl,
      if (rightFingerprintUrl != null)
        'rightFingerprintUrl': rightFingerprintUrl,
      if (cnicFrontUrl != null) 'cnicFrontUrl': cnicFrontUrl,
      if (cnicBackUrl != null) 'cnicBackUrl': cnicBackUrl,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (licenseExpiry != null) 'licenseExpiry': licenseExpiry,
      if (licenseFrontUrl != null) 'licenseFrontUrl': licenseFrontUrl,
      if (licenseBackUrl != null) 'licenseBackUrl': licenseBackUrl,
      if (utilityBillUrl != null) 'utilityBillUrl': utilityBillUrl,
      if (extraDocumentUrls.isNotEmpty)
        'extraDocumentUrls': extraDocumentUrls,
      if (signatureUrl != null) 'signatureUrl': signatureUrl,
      if (guarantorCustomerId != null)
        'guarantorCustomerId': guarantorCustomerId,
      if (guarantorRelation != null) 'guarantorRelation': guarantorRelation,
      'approvalStatus': approvalStatus,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
      'pushNotifications': pushNotifications,
      'whatsappNotifications': whatsappNotifications,
      'savedShopIds': savedShopIds,
      if (shopStatuses != null && shopStatuses!.isNotEmpty)
        'shopStatuses': shopStatuses,
    };
  }

  /// Reads `shopStatuses` defensively: a missing key reads as null,
  /// non-string keys/values are skipped, and an empty (or fully
  /// skipped) map normalises to null so a record with no statuses
  /// round-trips exactly like a legacy record without the key.
  static Map<String, String>? _parseShopStatuses(Object? raw) {
    if (raw is! Map) return null;
    final parsed = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is String) parsed[key] = value;
    }
    return parsed.isEmpty ? null : parsed;
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return CustomerModel(
      customerId: id ?? (map['customerId'] as String? ?? ''),
      shopId: (map['shopId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      cnic: map['cnic'] as String?,
      source: (map['source'] as String?) ?? 'walk_in',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dateOfBirth: map['dateOfBirth'] as String?,
      cnicExpiry: map['cnicExpiry'] as String?,
      fatherName: map['fatherName'] as String?,
      address: map['address'] as String?,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      thumbprintUrl: map['thumbprintUrl'] as String?,
      leftFingerprintUrl: map['leftFingerprintUrl'] as String?,
      rightFingerprintUrl: map['rightFingerprintUrl'] as String?,
      cnicFrontUrl: map['cnicFrontUrl'] as String?,
      cnicBackUrl: map['cnicBackUrl'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      licenseExpiry: map['licenseExpiry'] as String?,
      licenseFrontUrl: map['licenseFrontUrl'] as String?,
      licenseBackUrl: map['licenseBackUrl'] as String?,
      utilityBillUrl: map['utilityBillUrl'] as String?,
      extraDocumentUrls:
          (map['extraDocumentUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      signatureUrl: map['signatureUrl'] as String?,
      guarantorCustomerId: map['guarantorCustomerId'] as String?,
      guarantorRelation: map['guarantorRelation'] as String?,
      approvalStatus: (map['approvalStatus'] as String?) ?? 'pending',
      rejectionReason: map['rejectionReason'] as String?,
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.tryParse(map['reviewedAt'].toString())
          : null,
      shopStatuses: _parseShopStatuses(map['shopStatuses']),
    );
  }

  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      customerId: entity.customerId,
      shopId: entity.shopId,
      name: entity.name,
      phone: entity.phone,
      cnic: entity.cnic,
      source: entity.source,
      createdAt: entity.createdAt,
      dateOfBirth: entity.dateOfBirth,
      cnicExpiry: entity.cnicExpiry,
      fatherName: entity.fatherName,
      address: entity.address,
      profilePhotoUrl: entity.profilePhotoUrl,
      thumbprintUrl: entity.thumbprintUrl,
      leftFingerprintUrl: entity.leftFingerprintUrl,
      rightFingerprintUrl: entity.rightFingerprintUrl,
      cnicFrontUrl: entity.cnicFrontUrl,
      cnicBackUrl: entity.cnicBackUrl,
      licenseNumber: entity.licenseNumber,
      licenseExpiry: entity.licenseExpiry,
      licenseFrontUrl: entity.licenseFrontUrl,
      licenseBackUrl: entity.licenseBackUrl,
      utilityBillUrl: entity.utilityBillUrl,
      extraDocumentUrls: entity.extraDocumentUrls,
      signatureUrl: entity.signatureUrl,
      guarantorCustomerId: entity.guarantorCustomerId,
      guarantorRelation: entity.guarantorRelation,
      approvalStatus: entity.approvalStatus,
      rejectionReason: entity.rejectionReason,
      reviewedAt: entity.reviewedAt,
      shopStatuses: entity.shopStatuses,
    );
  }
}
