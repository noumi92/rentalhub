import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class SaveCustomerUseCase {
  final CustomerRepository repository;
  const SaveCustomerUseCase(this.repository);

  Future<void> call(CustomerEntity customer) {
    if (customer.name.trim().isEmpty) {
      throw ArgumentError('A customer needs a name.');
    }
    if (customer.phone.trim().isEmpty) {
      throw ArgumentError('A customer needs a phone number.');
    }
    return repository.upsertCustomer(customer);
  }
}
