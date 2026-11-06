import '../../../core/di/injection_container.dart';
import '../domain/entities/customer_entity.dart';
import '../domain/usecases/save_customer_usecase.dart';

/// Phase B (C1): saves a walk-in customer with their CNIC so they
/// show up in the customers list. A failed save must never fail the
/// booking itself — the caller swallows errors from this helper.
Future<void> saveWalkInCustomer({
  required String shopId,
  required String name,
  required String phone,
  required String cnic,
  required String fallbackCustomerId,
}) async {
  final digits = cnic.replaceAll(RegExp(r'\D'), '');
  await sl<SaveCustomerUseCase>()(CustomerEntity(
    customerId:
        digits.isNotEmpty ? 'cust-$digits' : fallbackCustomerId,
    shopId: shopId,
    name: name,
    phone: phone,
    cnic: cnic,
    source: 'walk_in',
    createdAt: DateTime.now(),
  ));
}
