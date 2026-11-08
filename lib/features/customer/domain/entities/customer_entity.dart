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

  /// H2: notification preferences, persisted on the customer record.
  /// Actual push delivery is backend/FCM (out of scope) — these record
  /// what the customer wants.
  final bool pushNotifications;
  final bool whatsappNotifications;

  /// H5: showrooms the customer saved (heart on the shop detail
  /// screen). Stored on the customer record, per the plan.
  final List<String> savedShopIds;

  const CustomerEntity({
    required this.customerId,
    required this.shopId,
    required this.name,
    required this.phone,
    this.cnic,
    this.source = 'walk_in',
    required this.createdAt,
    this.dateOfBirth,
    this.cnicExpiry,
    this.fatherName,
    this.address,
    this.pushNotifications = true,
    this.whatsappNotifications = true,
    this.savedShopIds = const [],
  });

  CustomerEntity copyWith({
    String? name,
    String? phone,
    String? cnic,
    String? source,
    String? dateOfBirth,
    String? cnicExpiry,
    String? fatherName,
    String? address,
    bool? pushNotifications,
    bool? whatsappNotifications,
    List<String>? savedShopIds,
  }) {
    return CustomerEntity(
      customerId: customerId,
      shopId: shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      source: source ?? this.source,
      createdAt: createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cnicExpiry: cnicExpiry ?? this.cnicExpiry,
      fatherName: fatherName ?? this.fatherName,
      address: address ?? this.address,
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
        pushNotifications,
        whatsappNotifications,
        savedShopIds,
        createdAt,
        dateOfBirth,
        cnicExpiry,
        fatherName,
        address,
      ];
}
