import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> getShopCustomers(String shopId);
  Future<CustomerEntity?> getCustomerByCnic(String shopId, String cnic);
  Future<void> upsertCustomer(CustomerEntity customer);

  /// Walk-in CRM: sets one shop's per-shop status for a customer
  /// ('active' | 'blocked' | 'archived') in `shopStatuses`, merging
  /// with the other shops' entries. Never hard-deletes the record.
  Future<void> updateCustomerStatus({
    required String customerId,
    required String shopId,
    required String status,
  });

  /// Walk-in CRM: archives the customer for one shop — a
  /// [updateCustomerStatus] with status 'archived'. The record and
  /// its history are kept; the customer is only hidden from the
  /// active list.
  Future<void> archiveCustomer({
    required String customerId,
    required String shopId,
  });
}
