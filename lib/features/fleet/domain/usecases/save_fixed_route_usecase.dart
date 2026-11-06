import '../entities/fixed_route_entity.dart';
import '../repositories/fixed_route_repository.dart';

class SaveFixedRouteUseCase {
  final FixedRouteRepository repository;
  const SaveFixedRouteUseCase(this.repository);

  Future<void> call(FixedRouteEntity route) {
    if (route.originCity.trim().isEmpty ||
        route.destinationCity.trim().isEmpty) {
      throw ArgumentError('A fixed route needs an origin and a destination.');
    }
    if (route.fixedPricePkr <= 0) {
      throw ArgumentError('A fixed route needs a price above zero.');
    }
    return repository.saveFixedRoute(route);
  }
}
