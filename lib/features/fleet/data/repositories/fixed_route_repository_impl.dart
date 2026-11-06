import '../../domain/entities/fixed_route_entity.dart';
import '../../domain/repositories/fixed_route_repository.dart';
import '../datasources/fixed_route_remote_data_source.dart';

class FixedRouteRepositoryImpl implements FixedRouteRepository {
  final FixedRouteRemoteDataSource remoteDataSource;
  const FixedRouteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FixedRouteEntity>> getShopFixedRoutes(String shopId) =>
      remoteDataSource.getShopFixedRoutes(shopId);

  @override
  Future<void> saveFixedRoute(FixedRouteEntity route) =>
      remoteDataSource.saveFixedRoute(route);

  @override
  Future<void> deleteFixedRoute(String routeId) =>
      remoteDataSource.deleteFixedRoute(routeId);
}
