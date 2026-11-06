import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetShopCustomersUseCase {
  final CustomerRepository repository;
  const GetShopCustomersUseCase(this.repository);

  Future<List<CustomerEntity>> call(String shopId) =>
      repository.getShopCustomers(shopId);
}
