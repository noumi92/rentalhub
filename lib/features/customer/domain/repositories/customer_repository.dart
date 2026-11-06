import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> getShopCustomers(String shopId);
  Future<CustomerEntity?> getCustomerByCnic(String shopId, String cnic);
  Future<void> upsertCustomer(CustomerEntity customer);
}
