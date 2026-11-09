import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/firestore_service.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/utils/settlement_calculator.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../handover/data/datasources/handover_local_data_source.dart';
import 'handover_photo_upload_service.dart' show ReturnRecordsService;

/// Gap (c): the vehicle's out-of-city pricing as it stands at
/// return time — the fallback when the booking carries no pricing
/// snapshot of its own (older bookings). `driverNightStayPkr` is
/// resolved here (Rs 2,000 deck default when unset, the same default
/// the fare breakdown and the PDF use) so the pure settlement math
/// downstream only ever sees ints.
class PerKmPricing {
  final String? outCityMode;
  final int? outCityPerKmPkr;
  final int driverAllowancePerDay;
  final int driverNightStayPkr;

  const PerKmPricing({
    this.outCityMode,
    this.outCityPerKmPkr,
    this.driverAllowancePerDay = 0,
    this.driverNightStayPkr = 2000,
  });
}

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
    int deductibleDamage,
    int extraCharges,
    PerKmPricing perKmPricing,
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
    var perKmPricing = const PerKmPricing();
    // Audit item 6 (O27/O28): damage reports and extra charges
    // recorded on their own screens fold into the settlement.
    var deductibleDamage = 0;
    var extraCharges = 0;
    try {
      final totals =
          await ReturnRecordsService().loadTotals(booking.bookingId);
      deductibleDamage = totals.deductibleDamage;
      extraCharges = totals.extraCharges;
    } catch (_) {}
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
        perKmPricing = PerKmPricing(
          outCityMode: vehicle.first.outCityMode,
          outCityPerKmPkr: vehicle.first.outCityPerKmPkr,
          driverAllowancePerDay:
              vehicle.first.withDriverSurchargePkr ?? 0,
          driverNightStayPkr: vehicle.first.driverNightStayPkr ?? 2000,
        );
      }
      if (depositRecord != null) deposit = depositRecord.amount;
    } catch (_) {}
    return (
      initialOdometer: initialOdometer,
      handoverDamageNotes: handoverNotes,
      extraKmPkr: extraKmPkr,
      extraHourPkr: extraHourPkr,
      deposit: deposit,
      deductibleDamage: deductibleDamage,
      extraCharges: extraCharges,
      perKmPricing: perKmPricing,
    );
  }

  /// Gap (c): whether this booking settles per-km, and the
  /// reconciliation on its actual km. The booking's own pricing
  /// snapshot wins — it is the rate agreed at booking time; the
  /// vehicle's current rates are only the fallback for older
  /// bookings that carry no snapshot. Returns null for every
  /// non-per-km booking (in-city, per-day and fixed-route trips all
  /// settle exactly as today — an in-city trip on a per-km-mode
  /// vehicle is priced by its in-city package, never per-km) and
  /// when no per-km rate is known.
  /// [totalKmDriven] is return odometer − the handover record's
  /// pickup odometer ([HandoverEntity.initialOdometer]) — the
  /// caller computes it, so no value is ever invented here. Days
  /// follow the same rule as the fare breakdown (sub-day counts as
  /// 1 day); nights are days − 1, out-of-city with-driver only.
  static PerKmSettlement? perKmSettlementFor({
    required BookingEntity booking,
    required int totalKmDriven,
    required PerKmPricing pricing,
  }) {
    final mode = booking.outCityMode ?? pricing.outCityMode;
    if (booking.tripType != 'out_of_city') return null;
    if (mode != 'perKm') return null;
    final rate = booking.outCityPerKmPkr ?? pricing.outCityPerKmPkr;
    if (rate == null || rate <= 0) return null;
    final minutes =
        booking.returnTime.difference(booking.pickupTime).inMinutes;
    final days = minutes <= 0 ? 1 : (minutes / (24 * 60)).ceil();
    final nights = booking.tripType == 'out_of_city' && booking.isWithDriver
        ? (days - 1).clamp(0, 1 << 30)
        : 0;
    return SettlementCalculator.calculatePerKm(
      actualKm: totalKmDriven,
      perKmRate: rate,
      driverAllowancePerDay: pricing.driverAllowancePerDay,
      days: days,
      isWithDriver: booking.isWithDriver,
      nightStayTotal: nights * pricing.driverNightStayPkr,
      estimatedFare: booking.totalAmount,
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
    // Audit item 5 (O25/O26): the return-inspection condition and
    // photos, the itemized records folded into the settlement, and
    // the remaining rent collected at return with its method.
    String condition = 'good',
    Map<String, String?> returnPhotoUrls = const {},
    int deductibleDamage = 0,
    int extraCharges = 0,
    int remainingRentCollected = 0,
    String? paymentMethod,
    // Gap (c): the per-km reconciliation for a per-km-mode booking
    // (null for every other booking). It is persisted on the
    // settlement doc below; it never changes the deposit math.
    PerKmSettlement? perKmSettlement,
  }) async {
    final totalKmDriven = (returnOdometer - initialOdometer).clamp(0, 99999);
    final overtimeHours = _overtimeHours(booking.returnTime);
    // Gap (c): a per-km trip has no included-km allowance — every
    // km is paid at the per-km rate through the reconciliation, so
    // the package excess-km charge must not also apply on top of it.
    final effectiveExtraKmPkr = perKmSettlement != null ? 0 : extraKmPkr;
    final breakdown = SettlementCalculator.calculate(
      totalKmDriven: totalKmDriven,
      kmAllowance: kmAllowance,
      extraKmPkr: effectiveExtraKmPkr,
      fuelLevel: fuelLevel,
      damageCharge: damageCharge + deductibleDamage,
      overtimeHours: overtimeHours,
      extraHourPkr: extraHourPkr,
      securityDeposit: deposit,
      extraCharges: extraCharges,
    );
    // The remaining rent collected here reduces what the customer
    // still owes; it is not a deposit deduction, so it never changes
    // the refund — it is recorded on the settlement doc below.
    final remainingRentDue =
        (booking.remainingBalance - remainingRentCollected).clamp(0, 1 << 30);

    // The return record: condition, photos, payment and totals, on
    // `return_settlements/{bookingId}` (merge). Firestore resolves
    // lazily — a failed write never fails the settlement itself.
    try {
      final fs = FirebaseFirestore.instance;
      await fs.collection('return_settlements').doc(booking.bookingId).set({
        'bookingId': booking.bookingId,
        'shopId': booking.shopId,
        'condition': condition,
        'returnPhotoUrls': {
          for (final e in returnPhotoUrls.entries)
            if (e.value != null) e.key: e.value,
        },
        'paymentMethod': paymentMethod,
        'remainingRentCollected': remainingRentCollected,
        'remainingRentDue': remainingRentDue,
        'deductibleDamage': deductibleDamage,
        'extraCharges': extraCharges,
        'totalDeductions': breakdown.totalDeductions,
        'netRefund': breakdown.netRefund,
        if (perKmSettlement != null) ...{
          'perKmMode': true,
          'perKmRate': perKmSettlement.perKmRate,
          'perKmActualKm': perKmSettlement.actualKm,
          'perKmActualFare': perKmSettlement.actualFare,
          'perKmEstimatedFare': perKmSettlement.estimatedFare,
          'perKmExtraDue': perKmSettlement.extraDue,
          'perKmRefundDue': perKmSettlement.refundDue,
        },
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

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

  /// Finish build (O26): the distinct "Refund Deposit" step. Reads the
  /// refund recorded on `return_settlements/{bookingId}` — absent (or
  /// unreadable, e.g. offline) resolves to "not recorded", never an
  /// error, so the return flow never blocks on this read. Goes through
  /// the DI [FirestoreService] (in-memory fallback in tests) instead
  /// of `FirebaseFirestore.instance`, which throws `core/no-app`
  /// wherever Firebase was never initialized.
  static Future<({bool recorded, int amount})> loadRefundState(
      String bookingId) async {
    try {
      final data = await sl<FirestoreService>()
          .getDocument('return_settlements', bookingId);
      if (data == null) return (recorded: false, amount: 0);
      return (
        recorded: data['refundRecorded'] == true,
        amount: (data['depositRefunded'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return (recorded: false, amount: 0);
    }
  }

  /// Finish build (O26): records the deposit refund as its own step on
  /// `return_settlements/{bookingId}` (merge — the settlement totals
  /// written by [finalizeReturn] are untouched, and no booking money
  /// field is mutated). Throws on failure so the caller can show the
  /// failure state instead of pretending the refund was recorded.
  static Future<void> recordRefund({
    required String bookingId,
    required int amount,
  }) async {
    await sl<FirestoreService>().setDocument(
      'return_settlements',
      bookingId,
      {
        'bookingId': bookingId,
        'refundRecorded': true,
        'depositRefunded': amount,
        'depositRefundedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      merge: true,
    );
  }
}
