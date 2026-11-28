import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/repositories/customer_repository.dart';

/// What the customer detail screen loads: the resolved record, the
/// shop's bookings for the customer (newest first), the blacklist
/// state, and the canonical shop DOCUMENT id (`shop_<uid>`) the
/// per-shop status map is keyed by.
class CustomerDetailData {
  final CustomerEntity? customer;
  final CustomerEntity? guarantor;
  final List<BookingEntity> bookings;
  final bool blacklisted;
  final String canonicalShopId;

  const CustomerDetailData({
    required this.customer,
    this.guarantor,
    required this.bookings,
    required this.blacklisted,
    required this.canonicalShopId,
  });
}

/// Walk-in CRM: the detail screen's data + mutations, extracted
/// from [OwnerCustomerDetailView] so the view stays under the
/// 250-line cap. The view owns feedback, the acting spinner and
/// rebuilds; this class owns the load and the writes (approval,
/// per-shop status, archive). Throws on load failure — the view
/// turns that into its error state.
class CustomerDetailController {
  final CustomerRemoteDataSource _customerDs;
  final BookingRemoteDataSource _bookingDs;
  final BlacklistRemoteDataSource _blacklistDs;
  final CustomerRepository _repository;

  CustomerDetailController({
    CustomerRemoteDataSource? customerDs,
    BookingRemoteDataSource? bookingDs,
    BlacklistRemoteDataSource? blacklistDs,
    CustomerRepository? repository,
  })  : _customerDs = customerDs ?? sl<CustomerRemoteDataSource>(),
        _bookingDs = bookingDs ?? sl<BookingRemoteDataSource>(),
        _blacklistDs = blacklistDs ?? sl<BlacklistRemoteDataSource>(),
        _repository = repository ?? sl<CustomerRepository>();

  /// The Firestore to resolve the shop id against, or null when
  /// Firebase is not initialised (tests) — the status then keeps
  /// the bare UID, as before.
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static String _digits(String? v) => (v ?? '').replaceAll(RegExp(r'\D'), '');

  Future<CustomerDetailData> load({
    required String customerId,
    required String shopId,
  }) async {
    final canonical = await canonicalShopId(_firestore, shopId);
    var customer = await _customerDs.getCustomerById(customerId);
    customer ??= await _customerDs.getCustomerByCnic(shopId, customerId);
    final all = await _bookingDs.getShopBookings(shopId);
    // Final capture: the `where` closure cannot promote the
    // mutable `customer` local (it is reassigned below).
    final resolved = customer;
    final bookings = all.where((b) {
      if (resolved != null) {
        return b.customerId == resolved.customerId || (_digits(b.customerCnic).isNotEmpty && _digits(b.customerCnic) == _digits(resolved.cnic));
      }
      return b.customerId == customerId || _digits(b.customerCnic) == _digits(customerId);
    }).toList()
      ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
    // No saved record: the customer is known only from bookings.
    // Synthesise a display record from the newest booking instead
    // of showing a fake "not found" for a real customer.
    customer ??= bookings.isEmpty
        ? null
        : CustomerEntity(customerId: bookings.first.customerId, shopId: shopId, name: bookings.first.customerName ?? '', phone: bookings.first.customerPhone ?? '', cnic: bookings.first.customerCnic, createdAt: bookings.last.pickupTime);
    final blacklisted = customer?.cnic != null && await _blacklistDs.isCnicBlacklisted(customer!.cnic!);
    CustomerEntity? guarantor;
    final gid = customer?.guarantorCustomerId;
    if (gid != null && gid.trim().isNotEmpty) {
      guarantor = await _customerDs.getCustomerById(gid);
    }
    return CustomerDetailData(
      customer: customer,
      guarantor: guarantor,
      bookings: bookings,
      blacklisted: blacklisted,
      canonicalShopId: canonical,
    );
  }

  Future<void> setApproval({
    required String customerId,
    required String status,
    String? reason,
  }) =>
      _customerDs.updateApprovalStatus(
          customerId: customerId, status: status, rejectionReason: reason);

  /// Writes one shop's per-shop status (validated by the data
  /// layer to 'active' | 'blocked' | 'archived').
  Future<void> setStatus({
    required String customerId,
    required String shopId,
    required String status,
  }) =>
      _repository.updateCustomerStatus(
          customerId: customerId, shopId: shopId, status: status);

  /// Delete = archive. There is no hard delete for customers.
  Future<void> archive({
    required String customerId,
    required String shopId,
  }) =>
      _repository.archiveCustomer(customerId: customerId, shopId: shopId);
}
