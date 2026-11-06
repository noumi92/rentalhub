import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../core/di/injection_container.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/utils/settlement_calculator.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../handover/data/datasources/handover_local_data_source.dart';

/// Phase B (F1/F2): the return settlement, extracted from
/// [OwnerReturnSettlementView] so the view stays under the 250-line
/// cap. Loads the real handover/vehicle/deposit values and writes
/// the settlement — the booking, the deposit record and the
/// vehicle's status and mileage.
class ReturnSettlementService {
  static Future<({
    int initialOdometer,
    List<String> handoverDamageNotes,
    int extraKmPkr,
    int extraHourPkr,
    int deposit,
  })> loadRealValues(
    BookingEntity booking, {
    int fallbackOdometer = 45200,
    int fallbackDeposit = 0,
  }) async {
    var initialOdometer = fallbackOdometer;
    var handoverNotes = const <String>[];
    var extraKmPkr = 100;
    var extraHourPkr = 0;
    var deposit = fallbackDeposit;
    try {
      // The handover record holds the true departure odometer and
      // the damage noted when the car left.
      final handover = await sl<HandoverLocalDataSource>()
          .getHandover(booking.bookingId);
      // The vehicle holds the real rates and the deposit it charges.
      final vehicles = await sl<FleetRemoteDataSource>()
          .getShopVehicles(booking.shopId);
      final vehicle = vehicles
          .where((v) => v.vehicleId == booking.vehicleId)
          .toList();
      // The deposit record, if the handover already collected it.
      final depositRecord = await sl<SecurityDepositDataSource>()
          .getByBookingId(booking.bookingId);
      if (handover != null) {
        initialOdometer = handover.initialOdometer;
        handoverNotes = handover.damageNotes;
      }
      if (vehicle.isNotEmpty) {
        extraKmPkr = vehicle.first.extraKmPkr ?? 100;
        extraHourPkr = vehicle.first.extraHourPkr ?? 0;
        deposit = vehicle.first.securityDepositPkr ?? deposit;
      }
      if (depositRecord != null) deposit = depositRecord.amount;
    } catch (_) {}
    return (
      initialOdometer: initialOdometer,
      handoverDamageNotes: handoverNotes,
      extraKmPkr: extraKmPkr,
      extraHourPkr: extraHourPkr,
      deposit: deposit,
    );
  }

  static Future<SettlementBreakdown> finalizeReturn({
    required BookingEntity booking,
    required int returnOdometer,
    required int initialOdometer,
    required int kmAllowance,
    required int extraKmPkr,
    required int extraHourPkr,
    required int deposit,
    required String fuelLevel,
    required List<String> returnDamageNotes,
    required int damageCharge,
  }) async {
    final totalKmDriven = (returnOdometer - initialOdometer).clamp(0, 99999);
    final overtimeHours = _overtimeHours(booking.returnTime);
    final breakdown = SettlementCalculator.calculate(
      totalKmDriven: totalKmDriven,
      kmAllowance: kmAllowance,
      extraKmPkr: extraKmPkr,
      fuelLevel: fuelLevel,
      damageCharge: damageCharge,
      overtimeHours: overtimeHours,
      extraHourPkr: extraHourPkr,
      securityDeposit: deposit,
    );

    final depositDs = sl<SecurityDepositDataSource>();
    // The handover normally collects the deposit; if it never did
    // (older bookings, a failed write), backfill it now so the
    // settlement still has a record to settle.
    var record = await depositDs.getByBookingId(booking.bookingId);
    record ??= await depositDs.collect(
      bookingId: booking.bookingId,
      customerId: booking.customerId,
      shopId: booking.shopId,
      amount: deposit,
      collectedAt: booking.pickupTime,
    );
    await depositDs.settle(
      bookingId: booking.bookingId,
      totalKmDriven: breakdown.totalKmDriven,
      excessKm: breakdown.excessKm,
      excessKmCharge: breakdown.excessKmCharge,
      fuelDeficit: breakdown.fuelDeficit,
      damageCharge: breakdown.damageCharge,
      overtimeFee: breakdown.overtimeFee,
      deductedAmount: breakdown.totalDeductions,
      netRefund: breakdown.netRefund,
      returnDamageNotes: returnDamageNotes,
    );

    final bookingDs = sl<BookingRemoteDataSource>();
    await bookingDs.updateBookingStatus(
      bookingId: booking.bookingId,
      status: 'completed',
    );

    final fleetDs = sl<FleetRemoteDataSource>();
    await fleetDs.updateVehicleStatus(
      vehicleId: booking.vehicleId,
      status: 'available',
    );
    await fleetDs.updateVehicleMileage(
      vehicleId: booking.vehicleId,
      mileageKm: returnOdometer,
    );
    return breakdown;
  }

  static int _overtimeHours(DateTime dueBack) {
    final late = DateTime.now().difference(dueBack);
    if (late.isNegative) return 0;
    return (late.inMinutes / 60).ceil();
  }
}
