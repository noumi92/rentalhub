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
      );

  @override
  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
  }) =>
      remoteDataSource.updateBookingStatus(
        bookingId: bookingId,
        status: status,
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

