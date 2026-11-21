import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  const CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CustomerEntity>> getShopCustomers(String shopId) =>
      remoteDataSource.getShopCustomers(shopId);

  @override
  Future<CustomerEntity?> getCustomerByCnic(String shopId, String cnic) =>
      remoteDataSource.getCustomerByCnic(shopId, cnic);

  @override
  Future<void> upsertCustomer(CustomerEntity customer) =>
      remoteDataSource.upsertCustomer(customer);

  @override
  Future<void> updateCustomerStatus({
    required String customerId,
    required String shopId,
    required String status,
  }) =>
      remoteDataSource.updateCustomerStatus(
        customerId: customerId,
        shopId: shopId,
        status: status,
      );

  @override
  Future<void> archiveCustomer({
    required String customerId,
    required String shopId,
  }) =>
      remoteDataSource.archiveCustomer(
        customerId: customerId,
        shopId: shopId,
      );
}
