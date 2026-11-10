import '../../../admin/data/repositories/platform_settings_repository.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_data_source.dart';

/// Admin-integration audit (2026-11-10): the nearby radar resolves
/// the `displayUnverifiedShops` platform setting itself (default ON,
/// fail-open) and passes it to the data source, so the admin toggle
/// governs this path exactly as it governs the Shops tab. The
/// repository/use-case/cubit signatures are unchanged — only this
/// implementation reads the setting.
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remoteDataSource;
  final PlatformSettingsRepository _settings;

  const DiscoveryRepositoryImpl({
    required this.remoteDataSource,
    PlatformSettingsRepository? settings,
  }) : _settings = settings ?? const PlatformSettingsRepository();

  @override
  Future<List<ShopEntity>> getNearbyShops({
    required double radiusKm,
    required double latitude,
    required double longitude,
  }) async {
    final includeUnverified =
        await _settings.displayUnverifiedShops();
    return remoteDataSource.fetchNearbyShops(
      radiusKm: radiusKm,
      latitude: latitude,
      longitude: longitude,
      includeUnverified: includeUnverified,
    );
  }
}
