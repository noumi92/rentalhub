import '../../../../core/error/exceptions.dart';
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
    final subscriptionTier = await repository.getShopSubscriptionTier(shopId);

    // Freemium rule: Free tier max 3 vehicles
    if (subscriptionTier == 'basic' && currentCount >= 3) {
      throw const BusinessRuleException(
        message:
            'Freemium limit reached. Basic free plan allows up to 3 cars. Please upgrade to Pro to add more vehicles.',
      );
    }

    return repository.addVehicle(shopId: shopId, vehicle: vehicle);
  }
}

