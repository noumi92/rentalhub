import '../entities/fixed_route_entity.dart';
import '../repositories/fixed_route_repository.dart';

class GetShopFixedRoutesUseCase {
  final FixedRouteRepository repository;
  const GetShopFixedRoutesUseCase(this.repository);

  Future<List<FixedRouteEntity>> call(String shopId) =>
      repository.getShopFixedRoutes(shopId);
}
