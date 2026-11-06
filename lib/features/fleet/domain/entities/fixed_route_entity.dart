import 'package:equatable/equatable.dart';

/// Phase B (B3): a fixed-price route from the shop's city to a
/// destination (e.g. Lahore → Islamabad). The owner sets the price;
/// customers see the route as a one-tap destination when they book
/// an out-of-city trip.
class FixedRouteEntity extends Equatable {
  final String routeId;
  final String shopId;
  final String originCity;
  final String destinationCity;
  final int distanceKm;
  final int fixedPricePkr;
  final bool enabled;

  const FixedRouteEntity({
    required this.routeId,
    required this.shopId,
    required this.originCity,
    required this.destinationCity,
    required this.distanceKm,
    required this.fixedPricePkr,
    this.enabled = true,
  });

  FixedRouteEntity copyWith({
    String? routeId,
    String? shopId,
    String? originCity,
    String? destinationCity,
    int? distanceKm,
    int? fixedPricePkr,
    bool? enabled,
  }) {
    return FixedRouteEntity(
      routeId: routeId ?? this.routeId,
      shopId: shopId ?? this.shopId,
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      distanceKm: distanceKm ?? this.distanceKm,
      fixedPricePkr: fixedPricePkr ?? this.fixedPricePkr,
      enabled: enabled ?? this.enabled,
    );
  }

  String get displayName => '$originCity → $destinationCity';

  @override
  List<Object?> get props => [
        routeId,
        shopId,
        originCity,
        destinationCity,
        distanceKm,
        fixedPricePkr,
        enabled,
      ];
}
