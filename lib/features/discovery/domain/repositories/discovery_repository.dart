import '../entities/shop_entity.dart';

abstract class DiscoveryRepository {
  Future<List<ShopEntity>> getNearbyShops({required double radiusKm});
}

