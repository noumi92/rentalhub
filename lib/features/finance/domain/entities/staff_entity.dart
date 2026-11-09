import 'package:equatable/equatable.dart';

/// Audit impl (O51): one staff member of a shop. The collection
/// name `staff` and these field names are a cross-worker contract
/// (worker E reads this collection for the subscription usage bar):
/// shopId / name / role / phone / permissions{viewBookings, addCars,
/// manageFinance} / createdAt. Do not rename them.
class StaffEntity extends Equatable {
  final String staffId;
  final String shopId;
  final String name;
  final String role;
  final String phone;
  final bool viewBookings;
  final bool addCars;
  final bool manageFinance;
  final DateTime createdAt;

  const StaffEntity({
    required this.staffId,
    required this.shopId,
    required this.name,
    required this.role,
    this.phone = '',
    this.viewBookings = true,
    this.addCars = false,
    this.manageFinance = false,
    required this.createdAt,
  });

  StaffEntity copyWith({
    String? name,
    String? role,
    String? phone,
    bool? viewBookings,
    bool? addCars,
    bool? manageFinance,
  }) {
    return StaffEntity(
      staffId: staffId,
      shopId: shopId,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      viewBookings: viewBookings ?? this.viewBookings,
      addCars: addCars ?? this.addCars,
      manageFinance: manageFinance ?? this.manageFinance,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        staffId,
        shopId,
        name,
        role,
        phone,
        viewBookings,
        addCars,
        manageFinance,
        createdAt,
      ];
}
