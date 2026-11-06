import '../entities/fixed_route_entity.dart';

abstract class FixedRouteRepository {
  Future<List<FixedRouteEntity>> getShopFixedRoutes(String shopId);
  Future<void> saveFixedRoute(FixedRouteEntity route);
  Future<void> deleteFixedRoute(String routeId);
}
