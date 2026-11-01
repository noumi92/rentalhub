import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_data_source.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remoteDataSource;

  const DiscoveryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ShopEntity>> getNearbyShops({required double radiusKm}) =>
      remoteDataSource.fetchNearbyShops(radiusKm: radiusKm);
}

