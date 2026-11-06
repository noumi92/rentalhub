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
  });

  CustomerEntity copyWith({
    String? name,
    String? phone,
    String? cnic,
    String? source,
    String? dateOfBirth,
    String? cnicExpiry,
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
        createdAt,
        dateOfBirth,
        cnicExpiry,
      ];
}
