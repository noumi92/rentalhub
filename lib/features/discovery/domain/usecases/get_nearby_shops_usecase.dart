import '../entities/shop_entity.dart';
import '../repositories/discovery_repository.dart';

class GetNearbyShopsUseCase {
  final DiscoveryRepository repository;
  const GetNearbyShopsUseCase(this.repository);

  Future<List<ShopEntity>> call({
    required double radiusKm,
    required double latitude,
    required double longitude,
  }) =>
      repository.getNearbyShops(
        radiusKm: radiusKm,
        latitude: latitude,
        longitude: longitude,
      );
}

