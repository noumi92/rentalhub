import '../../domain/entities/fixed_route_entity.dart';

class FixedRouteModel extends FixedRouteEntity {
  const FixedRouteModel({
    required super.routeId,
    required super.shopId,
    required super.originCity,
    required super.destinationCity,
    required super.distanceKm,
    required super.fixedPricePkr,
    super.enabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'shopId': shopId,
      'originCity': originCity,
      'destinationCity': destinationCity,
      'distanceKm': distanceKm,
      'fixedPricePkr': fixedPricePkr,
      'enabled': enabled,
    };
  }

  factory FixedRouteModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return FixedRouteModel(
      routeId: id ?? (map['routeId'] as String? ?? ''),
      shopId: (map['shopId'] as String?) ?? '',
      originCity: (map['originCity'] as String?) ?? '',
      destinationCity: (map['destinationCity'] as String?) ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toInt() ?? 0,
      fixedPricePkr: (map['fixedPricePkr'] as num?)?.toInt() ?? 0,
      enabled: (map['enabled'] as bool?) ?? true,
    );
  }

  factory FixedRouteModel.fromEntity(FixedRouteEntity entity) {
    return FixedRouteModel(
      routeId: entity.routeId,
      shopId: entity.shopId,
      originCity: entity.originCity,
      destinationCity: entity.destinationCity,
      distanceKm: entity.distanceKm,
      fixedPricePkr: entity.fixedPricePkr,
      enabled: entity.enabled,
    );
  }
}
