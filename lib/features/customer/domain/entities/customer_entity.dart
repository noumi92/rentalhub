import 'package:equatable/equatable.dart';

/// Phase B (C1): a customer record of one shop — a walk-in saved at
/// booking time, a person scanned by CNIC OCR, or a guarantor.
/// Online customers are also derived from their bookings (see
/// [OwnerCustomersListView]); this record is what carries their CNIC.
class CustomerEntity extends Equatable {
  final String customerId;
  final String shopId;
  final String name;
  final String phone;
  final String? cnic;
  final String source; // 'walk_in' | 'online' | 'ocr' | 'guarantor'
  final DateTime createdAt;

  /// Phase B (C2): filled by CNIC OCR when the card is scanned.
  final String? dateOfBirth;
  final String? cnicExpiry;

  /// Audit §20: Father's Name and Address were collected by the CNIC
  /// review form and then silently discarded — the entity had no
  /// fields for them. Both are nullable so older records (without
  /// them) keep round-tripping unchanged.
  final String? fatherName;
  final String? address;

  /// Add Customer wizard (O12–O15): the KYC media + documents the
  /// wizard captures. All nullable (older records predate the wizard)
  /// and all store URLs/keys only — never bytes. Face matching is
  /// NOT done in the app: the photo is saved and an admin reviews
  /// it manually, so there is no match score or isVerified flag here.
  final String? profilePhotoUrl;
  final String? thumbprintUrl;

  /// Fingerprint photos (one photo per hand showing the 4 fingers,
  /// rear camera). Photos, never scans — no SDK is in the app. Null
  /// for older records (predate the photos) and for customers added
  /// without a capture.
  final String? leftFingerprintUrl;
  final String? rightFingerprintUrl;

  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? licenseNumber;
  final String? licenseExpiry;
  final String? licenseFrontUrl;
  final String? licenseBackUrl;
  final String? utilityBillUrl;
  final List<String> extraDocumentUrls;
  final String? signatureUrl;
  final String? guarantorCustomerId;
  final String? guarantorRelation;
  final String? guarantorName;
  final String? guarantorPhone;
  final String? guarantorCnic;
  final String? guarantorAddress;

  /// Owner-deck finish (#35): owner approval of a customer profile.
  /// 'pending' | 'approved' | 'rejected'. New records start pending;
  /// older records without the field read as pending. [reviewedAt] is
  /// when the owner last approved or rejected the profile.
  final String approvalStatus;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  /// H2: notification preferences, persisted on the customer record.
  /// Actual push delivery is backend/FCM (out of scope) — these record
  /// what the customer wants.
  final bool pushNotifications;
  final bool whatsappNotifications;

  /// H5: showrooms the customer saved (heart on the shop detail
  /// screen). Stored on the customer record, per the plan.
  final List<String> savedShopIds;

  /// Walk-in customer CRM: per-shop status. Customer docs are
  /// CNIC-keyed globally (one doc per CNIC shared across shops), so
  /// a shop's view of a customer lives in this map keyed by the
  /// shop DOCUMENT id (`shop_<uid>`):
  /// * [statusActive] — the default; no entry for the shop means
  ///   active ([statusForShop] returns this).
  /// * [statusBlocked] — the shop blocked this customer.
  /// * [statusArchived] — soft-deleted by the shop (delete =
  ///   archive; there is no hard delete). Archived customers are
  ///   hidden from the shop's list but the record stays.
  /// Derived statuses (KYC Incomplete, Dormant 90d, Frequent) are
  /// computed by the UI from the record — never stored here.
  static const String statusActive = 'active';
  static const String statusBlocked = 'blocked';
  static const String statusArchived = 'archived';

  final Map<String, String>? shopStatuses;

  /// This shop's status for the customer: the stored value for
  /// [shopId], or [statusActive] when the shop has no entry. Both
  /// id forms are tried (bare owner UID and `shop_<uid>` doc id):
  /// writes canonicalize to the doc id, but older rows may carry
  /// either form, and a miss must read as active, never as an error.
  String statusForShop(String shopId) {
    final statuses = shopStatuses;
    if (statuses == null || statuses.isEmpty) return statusActive;
    if (statuses.containsKey(shopId)) return statuses[shopId]!;
    final prefixed = shopId.startsWith('shop_') ? shopId : 'shop_$shopId';
    if (statuses.containsKey(prefixed)) return statuses[prefixed]!;
    if (shopId.startsWith('shop_')) {
      final bare = shopId.substring('shop_'.length);
      if (statuses.containsKey(bare)) return statuses[bare]!;
    }
    return statusActive;
  }

  const CustomerEntity({
    required this.customerId,
    required this.shopId,
    required this.name,
    required this.phone,
    this.cnic,
    this.source = 'walk_in',
    required this.createdAt,
    this.shopStatuses,
    this.dateOfBirth,
    this.cnicExpiry,
    this.fatherName,
    this.address,
    this.profilePhotoUrl,
    this.thumbprintUrl,
    this.leftFingerprintUrl,
    this.rightFingerprintUrl,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.licenseNumber,
    this.licenseExpiry,
    this.licenseFrontUrl,
    this.licenseBackUrl,
    this.utilityBillUrl,
    this.extraDocumentUrls = const [],
    this.signatureUrl,
    this.guarantorCustomerId,
    this.guarantorRelation,
    this.guarantorName,
    this.guarantorPhone,
    this.guarantorCnic,
    this.guarantorAddress,
    this.approvalStatus = 'pending',
    this.rejectionReason,
    this.reviewedAt,
    this.pushNotifications = true,
    this.whatsappNotifications = true,
    this.savedShopIds = const [],
  });

  CustomerEntity copyWith({
    String? shopId,
    String? name,
    String? phone,
    String? cnic,
    String? source,
    Map<String, String>? shopStatuses,
    String? dateOfBirth,
    String? cnicExpiry,
    String? fatherName,
    String? address,
    String? profilePhotoUrl,
    String? thumbprintUrl,
    String? leftFingerprintUrl,
    String? rightFingerprintUrl,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? licenseNumber,
    String? licenseExpiry,
    String? licenseFrontUrl,
    String? licenseBackUrl,
    String? utilityBillUrl,
    List<String>? extraDocumentUrls,
    String? signatureUrl,
    String? guarantorCustomerId,
    String? guarantorRelation,
    String? guarantorName,
    String? guarantorPhone,
    String? guarantorCnic,
    String? guarantorAddress,
    String? approvalStatus,
    String? rejectionReason,
    bool clearRejectionReason = false,
    DateTime? reviewedAt,
    bool? pushNotifications,
    bool? whatsappNotifications,
    List<String>? savedShopIds,
  }) {
    return CustomerEntity(
      customerId: customerId,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      source: source ?? this.source,
      shopStatuses: shopStatuses ?? this.shopStatuses,
      createdAt: createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cnicExpiry: cnicExpiry ?? this.cnicExpiry,
      fatherName: fatherName ?? this.fatherName,
      address: address ?? this.address,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      thumbprintUrl: thumbprintUrl ?? this.thumbprintUrl,
      leftFingerprintUrl: leftFingerprintUrl ?? this.leftFingerprintUrl,
      rightFingerprintUrl:
          rightFingerprintUrl ?? this.rightFingerprintUrl,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      licenseFrontUrl: licenseFrontUrl ?? this.licenseFrontUrl,
      licenseBackUrl: licenseBackUrl ?? this.licenseBackUrl,
      utilityBillUrl: utilityBillUrl ?? this.utilityBillUrl,
      extraDocumentUrls: extraDocumentUrls ?? this.extraDocumentUrls,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      guarantorCustomerId: guarantorCustomerId ?? this.guarantorCustomerId,
      guarantorRelation: guarantorRelation ?? this.guarantorRelation,
      guarantorName: guarantorName ?? this.guarantorName,
      guarantorPhone: guarantorPhone ?? this.guarantorPhone,
      guarantorCnic: guarantorCnic ?? this.guarantorCnic,
      guarantorAddress: guarantorAddress ?? this.guarantorAddress,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: clearRejectionReason
          ? null
          : (rejectionReason ?? this.rejectionReason),
      reviewedAt: reviewedAt ?? this.reviewedAt,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      whatsappNotifications:
          whatsappNotifications ?? this.whatsappNotifications,
      savedShopIds: savedShopIds ?? this.savedShopIds,
    );
  }

  @override
  List<Object?> get props => [
        customerId,
        shopId,
        name,
        phone,
        cnic,
        source,
        shopStatuses,
        pushNotifications,
        whatsappNotifications,
        savedShopIds,
        createdAt,
        dateOfBirth,
        cnicExpiry,
        fatherName,
        address,
        profilePhotoUrl,
        thumbprintUrl,
        leftFingerprintUrl,
        rightFingerprintUrl,
        cnicFrontUrl,
        cnicBackUrl,
        licenseNumber,
        licenseExpiry,
        licenseFrontUrl,
        licenseBackUrl,
        utilityBillUrl,
        extraDocumentUrls,
        signatureUrl,
        guarantorCustomerId,
        guarantorRelation,
        guarantorName,
        guarantorPhone,
        guarantorCnic,
        guarantorAddress,
        approvalStatus,
        rejectionReason,
        reviewedAt,
      ];
}
