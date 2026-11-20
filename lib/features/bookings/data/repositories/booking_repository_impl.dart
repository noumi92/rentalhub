import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  const BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<BookingEntity> createBookingRequest({
    required String customerId,
    required String shopId,
    required String vehicleId,
    required String packageType,
    required bool isWithDriver,
    required DateTime pickupTime,
    required DateTime returnTime,
    required int totalAmount,
    required int advanceRequired,
    String? fixedRouteId,
    String? fixedRouteSummary,
    String? outCityMode,
    int? outCityPerKmPkr,
    String? advancePaymentMethod,
    String? depositPaymentMethod,
  }) =>
      remoteDataSource.createBookingRequest(
        customerId: customerId,
        shopId: shopId,
        vehicleId: vehicleId,
        packageType: packageType,
        isWithDriver: isWithDriver,
        pickupTime: pickupTime,
        returnTime: returnTime,
        totalAmount: totalAmount,
        advanceRequired: advanceRequired,
        fixedRouteId: fixedRouteId,
        fixedRouteSummary: fixedRouteSummary,
        outCityMode: outCityMode,
        outCityPerKmPkr: outCityPerKmPkr,
        advancePaymentMethod: advancePaymentMethod,
        depositPaymentMethod: depositPaymentMethod,
      );

  @override
  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
    String? selectedPaymentAccount,
    DateTime? paymentDeadline,
  }) =>
      remoteDataSource.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        selectedPaymentAccount: selectedPaymentAccount,
        paymentDeadline: paymentDeadline,
      );

  @override
  Future<BookingEntity> updatePaymentProof({
    required String bookingId,
    required String paymentProofUrl,
    required String transactionId,
  }) =>
      remoteDataSource.updatePaymentProof(
        bookingId: bookingId,
        paymentProofUrl: paymentProofUrl,
        transactionId: transactionId,
      );

  @override
  Future<BookingEntity> verifyPayment({
    required String bookingId,
    required int advanceAmount,
  }) =>
      remoteDataSource.verifyPayment(
        bookingId: bookingId,
        advanceAmount: advanceAmount,
      );

  @override
  Future<BookingEntity> recordBalanceCollected({
    required String bookingId,
    required int amount,
  }) =>
      remoteDataSource.recordBalanceCollected(
        bookingId: bookingId,
        amount: amount,
      );

  @override
  Future<BookingEntity> recordExtraFare({
    required String bookingId,
    required int extraDue,
    required int collected,
  }) =>
      remoteDataSource.recordExtraFare(
        bookingId: bookingId,
        extraDue: extraDue,
        collected: collected,
      );

  @override
  Future<List<BookingEntity>> getCustomerBookings(String customerId) =>
      remoteDataSource.getCustomerBookings(customerId);

  @override
  Stream<List<BookingEntity>> streamCustomerBookings(String customerId) =>
      remoteDataSource.streamCustomerBookings(customerId);

  @override
  Stream<List<BookingEntity>> streamShopBookings(String shopId) =>
      remoteDataSource.streamShopBookings(shopId);

  @override
  Stream<List<BookingEntity>> streamVehicleBookings(String vehicleId) =>
      remoteDataSource.streamVehicleBookings(vehicleId);

  @override
  Stream<BookingEntity?> streamBooking(String bookingId) =>
      remoteDataSource.streamBooking(bookingId);
}

