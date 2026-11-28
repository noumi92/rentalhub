import '../../../../core/error/exceptions.dart';
import '../../../owner/presentation/services/subscription_plans.dart';
import '../entities/vehicle_entity.dart';
import '../repositories/fleet_repository.dart';

class AddVehicleUseCase {
  final FleetRepository repository;

  const AddVehicleUseCase(this.repository);

  Future<void> call({
    required String shopId,
    required VehicleEntity vehicle,
  }) async {
    final currentCount = await repository.getActiveVehicleCount(shopId);
    final rawTier = await repository.getShopSubscriptionTier(shopId);
    final tier = normalizeSubscriptionTier(rawTier);

    // Freemium rule: Free tier max 3 vehicles (normalizes legacy 'basic' -> 'free').
    if (tier == 'free' && currentCount >= 3) {
      throw const BusinessRuleException(
        message:
            'Free plan allows up to 3 vehicles. Pro and Business plans are coming soon — contact support if you need higher capacity.',
      );
    }

    return repository.addVehicle(shopId: shopId, vehicle: vehicle);
  }
}
