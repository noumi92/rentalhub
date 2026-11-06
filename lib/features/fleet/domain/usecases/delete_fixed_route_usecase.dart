import '../repositories/fixed_route_repository.dart';

class DeleteFixedRouteUseCase {
  final FixedRouteRepository repository;
  const DeleteFixedRouteUseCase(this.repository);

  Future<void> call(String routeId) =>
      repository.deleteFixedRoute(routeId);
}
