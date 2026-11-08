import '../../../core/di/injection_container.dart';
import '../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../domain/entities/customer_entity.dart';
import '../domain/usecases/save_customer_usecase.dart';

/// Thrown when the CNIC being saved is on the shared blacklist.
/// Carries no message — callers render a localized refusal, never
/// this exception's text, so no hardcoded English reaches the UI.
class BlacklistedCustomerException implements Exception {
  final String cnic;
  const BlacklistedCustomerException(this.cnic);
}

/// Phase B (C1): saves a walk-in customer with their CNIC so they
/// show up in the customers list. A failed save must never fail the
/// booking itself — the caller swallows errors from this helper.
///
/// Audit §21: the blacklist is checked here (not only in the scan
/// view) so BOTH callers — the Add Customer form and the manual
/// walk-in booking path — refuse a blacklisted CNIC. A blacklisted
/// CNIC throws [BlacklistedCustomerException] and nothing is written.
Future<void> saveWalkInCustomer({
  required String shopId,
  required String name,
  required String phone,
  required String cnic,
  required String fallbackCustomerId,
}) async {
  if (await sl<BlacklistRemoteDataSource>().isCnicBlacklisted(cnic)) {
    throw BlacklistedCustomerException(cnic);
  }
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
