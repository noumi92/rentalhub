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
    super.pushNotifications,
    super.whatsappNotifications,
    super.savedShopIds,
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
      'pushNotifications': pushNotifications,
      'whatsappNotifications': whatsappNotifications,
      'savedShopIds': savedShopIds,
    };
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
    );
  }
}
