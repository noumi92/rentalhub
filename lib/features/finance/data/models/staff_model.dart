import '../../domain/entities/staff_entity.dart';

class StaffModel extends StaffEntity {
  const StaffModel({
    required super.staffId,
    required super.shopId,
    required super.name,
    required super.role,
    super.phone,
    super.viewBookings,
    super.addCars,
    super.manageFinance,
    required super.createdAt,
  });

  factory StaffModel.fromEntity(StaffEntity e) {
    return StaffModel(
      staffId: e.staffId,
      shopId: e.shopId,
      name: e.name,
      role: e.role,
      phone: e.phone,
      viewBookings: e.viewBookings,
      addCars: e.addCars,
      manageFinance: e.manageFinance,
      createdAt: e.createdAt,
    );
  }

  factory StaffModel.fromMap(Map<String, dynamic> map) {
    final permissions = map['permissions'];
    final perms = permissions is Map
        ? Map<String, dynamic>.from(permissions)
        : const <String, dynamic>{};
    return StaffModel(
      staffId: map['staffId'] ?? '',
      shopId: map['shopId'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'] ?? '',
      viewBookings: perms['viewBookings'] == true,
      addCars: perms['addCars'] == true,
      manageFinance: perms['manageFinance'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'shopId': shopId,
      'name': name,
      'role': role,
      'phone': phone,
      'permissions': {
        'viewBookings': viewBookings,
        'addCars': addCars,
        'manageFinance': manageFinance,
      },
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
