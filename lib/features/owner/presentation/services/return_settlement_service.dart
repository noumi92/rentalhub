import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/firestore_service.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/data/services/booking_ledger_service.dart';
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
      // Item 2: the same effective-deposit rule [finalizeReturn]
      // applies (a handover that picked a deposit method but never
      // received it means nothing was held). Without this the
      // return screen settled its live receipt — and the refund
      // step recorded its amount — against the VEHICLE's deposit
      // while finalize settled against Rs 0, so the receipt, the
      // recorded refund and the settlement doc disagreed and the
      // ledger posted a refund for money never taken.
      if (depositRecord == null &&
          handover != null &&
          handover.depositPaymentMethod != null &&
          handover.depositReceivedAt == null) {
        deposit = 0;
      }
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
    // Per-km extra fare (2026-11-20): the part of the extra fare
    // the owner collected at return, with its method. Clamped to
    // the extra due inside; the remainder goes onto the dues.
    int extraFareCollected = 0,
    String? extraFarePaymentMethod,
  }) async {
    final totalKmDriven = (returnOdometer - initialOdometer).clamp(0, 99999);
    final overtimeHours = _overtimeHours(booking.returnTime);
    // Gap (c): a per-km trip has no included-km allowance — every
    // km is paid at the per-km rate through the reconciliation, so
    // the package excess-km charge must not also apply on top of it.
    final effectiveExtraKmPkr = perKmSettlement != null ? 0 : extraKmPkr;
    // Financial audit (2026-11-20): the deposit actually held.
    // The handover may have recorded a method but never the
    // receipt (Received toggle OFF) — then nothing was held, and
    // settling deductions against the vehicle's deposit would
    // refund money the shop never took. A deposit record that
    // exists (counter or handover) is authoritative and wins over
    // the handover flag. Older bookings with no handover record
    // keep the old behaviour (the vehicle's deposit).
    var effectiveDeposit = deposit;
    try {
      final handover = await sl<HandoverLocalDataSource>()
          .getHandover(booking.bookingId);
      final held = await sl<SecurityDepositDataSource>()
          .getByBookingId(booking.bookingId);
      if (held == null &&
          handover != null &&
          handover.depositPaymentMethod != null &&
          handover.depositReceivedAt == null) {
        effectiveDeposit = 0;
      }
    } catch (_) {}
    final breakdown = SettlementCalculator.calculate(
      totalKmDriven: totalKmDriven,
      kmAllowance: kmAllowance,
      extraKmPkr: effectiveExtraKmPkr,
      fuelLevel: fuelLevel,
      damageCharge: damageCharge + deductibleDamage,
      overtimeHours: overtimeHours,
      extraHourPkr: extraHourPkr,
      securityDeposit: effectiveDeposit,
      extraCharges: extraCharges,
    );
    // The remaining rent collected here reduces what the customer
    // still owes; it is not a deposit deduction, so it never changes
    // the refund — it is recorded on the settlement doc below.
    final remainingRentDue =
        (booking.remainingBalance - remainingRentCollected).clamp(0, 1 << 30);

    // Per-km extra fare (2026-11-20): the actual-km fare above the
    // booked estimate. Collected at return when the owner marks it
    // received; whatever is left goes onto the customer's dues (see
    // the [recordExtraFare] call below). Clamped on both ends so a
    // collected amount can never also sit in dues, and a stray
    // collection without a per-km settlement collects nothing.
    final extraDue = perKmSettlement?.extraDue ?? 0;
    final extraCollected = extraFareCollected.clamp(0, extraDue);
    final extraRemainder = extraDue - extraCollected;

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
        // Item 2: the deposit actually held and what is still owed
        // — the receipt reads these back, so a reopened settlement
        // shows the same numbers the return screen settled against
        // instead of re-deriving them from the vehicle's deposit.
        'securityDeposit': effectiveDeposit,
        'amountOwed': breakdown.amountOwed,
        if (perKmSettlement != null) ...{
          'perKmMode': true,
          'perKmRate': perKmSettlement.perKmRate,
          'perKmActualKm': perKmSettlement.actualKm,
          'perKmActualFare': perKmSettlement.actualFare,
          'perKmEstimatedFare': perKmSettlement.estimatedFare,
          'perKmExtraDue': perKmSettlement.extraDue,
          'perKmRefundDue': perKmSettlement.refundDue,
          'extraFareCollected': extraCollected,
          'extraFareCollectionMethod': extraFarePaymentMethod,
          'extraFareRemainder': extraRemainder,
        },
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    final depositDs = sl<SecurityDepositDataSource>();
    // The handover normally collects the deposit; if it never did
    // (older bookings, a failed write), backfill it now so the
    // settlement still has a record to settle. When the handover
    // shows the deposit was never received, the backfill is for
    // Rs 0 — nothing was held, so the deductions surface as
    // amount owed instead of being netted against phantom money.
    var record = await depositDs.getByBookingId(booking.bookingId);
    record ??= await depositDs.collect(
      bookingId: booking.bookingId,
      customerId: booking.customerId,
      shopId: booking.shopId,
      amount: effectiveDeposit,
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
    // Financial audit (2026-11-20): the remaining rent collected
    // at return used to live only on the settlement doc — the
    // booking kept its old remaining balance, so a fully-paid
    // completed booking stayed in the dues list forever. Applying
    // it here clears the due, and the ledger post below records
    // the cash exactly once. Clamped to what was still owed, so a
    // stray over-collection can never over-pay the booking or
    // over-post the ledger.
    final rentCollected =
        remainingRentCollected.clamp(0, booking.remainingBalance);
    if (rentCollected > 0) {
      await bookingDs.recordBalanceCollected(
        bookingId: booking.bookingId,
        amount: rentCollected,
      );
    }
    // Per-km extra fare (2026-11-20): the fare grew by the extra,
    // so the total grows with it and the collected part counts as
    // paid — the remainder stays in the remaining balance and
    // shows in the dues list on this completed booking. Applied
    // after the rent collection above (which clamped to the old
    // balance, so it could never eat the extra), and awaited, not
    // best-effort: a failure here fails the settlement rather than
    // silently dropping money the customer still owes.
    if (extraDue > 0) {
      await bookingDs.recordExtraFare(
        bookingId: booking.bookingId,
        extraDue: extraDue,
        collected: extraCollected,
      );
    }
    await bookingDs.updateBookingStatus(
      bookingId: booking.bookingId,
      status: 'completed',
    );

    // Financial audit (2026-11-20): the return cash, posted to
    // the ledger exactly once (deterministic ids) — the remaining
    // rent, the deposit refund and the collected owed amount all
    // used to live only on `return_settlements/{bookingId}`, so
    // account balances and cash closing missed real cash. The
    // refund / owed amounts are read back from the settlement doc
    // (they were recorded as separate steps before close).
    // Best-effort: a ledger failure never fails the settlement.
    await _postReturnCash(
      booking: booking,
      remainingRentCollected: rentCollected,
      paymentMethod: paymentMethod,
      extraFareCollected: extraCollected,
      extraFarePaymentMethod: extraFarePaymentMethod,
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

  static Future<void> _postReturnCash({
    required BookingEntity booking,
    required int remainingRentCollected,
    required String? paymentMethod,
    int extraFareCollected = 0,
    String? extraFarePaymentMethod,
  }) async {
    try {
      if (!sl.isRegistered<BookingLedgerService>()) return;
      final ledger = sl<BookingLedgerService>();
      if (remainingRentCollected > 0) {
        await ledger.postOnce(
          booking: booking,
          event: 'rent-return',
          kind: 'income',
          category: 'rent',
          amount: remainingRentCollected,
          paymentMethod: paymentMethod,
          note: 'Remaining rent collected at return for ${booking.bookingId}',
        );
      }
      // Per-km extra fare (2026-11-20): its own deterministic id
      // (`LEDGER-<id>-extra-fare`), so it can never collide with
      // or double the remaining-rent posting above. P&L treatment
      // is the same as the remaining rent: the fare is now part of
      // the booking's total (see recordExtraFare), so the
      // booking-revenue exclusion in FinanceSummary keeps this
      // posting out of P&L income and the fare is counted exactly
      // once, as booking revenue — never hidden, never doubled.
      // The cash itself still counts in account balances and cash
      // closing.
      if (extraFareCollected > 0) {
        await ledger.postOnce(
          booking: booking,
          event: 'extra-fare',
          kind: 'income',
          category: 'rent',
          amount: extraFareCollected,
          paymentMethod: extraFarePaymentMethod,
          note:
              'Per-km extra fare collected at return for ${booking.bookingId}',
        );
      }
      final settlement = await sl<FirestoreService>()
          .getDocument('return_settlements', booking.bookingId);
      if (settlement == null) return;
      final refunded = (settlement['depositRefunded'] as num?)?.toInt() ?? 0;
      if (settlement['refundRecorded'] == true && refunded > 0) {
        await ledger.postOnce(
          booking: booking,
          event: 'deposit-refund',
          kind: 'expense',
          category: 'deposit_refund',
          amount: refunded,
          note: 'Deposit refund for ${booking.bookingId}',
        );
      }
      final owed = (settlement['owedCollected'] as num?)?.toInt() ?? 0;
      if (owed > 0) {
        await ledger.postOnce(
          booking: booking,
          event: 'owed',
          kind: 'income',
          category: 'other',
          amount: owed,
          paymentMethod: settlement['owedCollectionMethod'] as String?,
          note: 'Owed amount collected at return for ${booking.bookingId}',
        );
      }
    } catch (_) {}
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
  ///
  /// Item 2: the refund is also posted to the ledger here
  /// (best-effort, `LEDGER-<id>-deposit-refund` via [BookingLedgerService.postOnce],
  /// so exactly once). Before this the ledger post lived only in
  /// [_postReturnCash], which re-read the settlement doc at finalize
  /// time — a failed read there (offline / transient) lost the
  /// refund expense permanently, with no retry: the deposit record
  /// said refunded, the summary said refunded, the ledger said
  /// nothing. Finalize still posts as a backstop; the deterministic
  /// id dedupes the two.
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
    if (amount <= 0) return;
    try {
      if (!sl.isRegistered<BookingLedgerService>() ||
          !sl.isRegistered<BookingRemoteDataSource>()) {
        return;
      }
      final booking =
          await sl<BookingRemoteDataSource>().getBookingById(bookingId);
      if (booking == null) return;
      await sl<BookingLedgerService>().postOnce(
        booking: booking,
        event: 'deposit-refund',
        kind: 'expense',
        category: 'deposit_refund',
        amount: amount,
        note: 'Deposit refund for $bookingId',
      );
    } catch (_) {}
  }

  /// Audit 2026-11-15 PW-21: records the collected owed amount — the
  /// excess over the deposit ([SettlementBreakdown.amountOwed]) the
  /// owner collected at return — as its own step on
  /// `return_settlements/{bookingId}` (merge, mirroring
  /// [recordRefund]). The collection step used to be in-session only:
  /// closing the screen lost the record. Throws on failure so the
  /// caller shows the failure state instead of pretending the
  /// collection landed. [amount] 0 with no method clears a previous
  /// collection (undo).
  static Future<void> recordOwedCollected({
    required String bookingId,
    required int amount,
    String? method,
  }) async {
    await sl<FirestoreService>().setDocument(
      'return_settlements',
      bookingId,
      {
        'bookingId': bookingId,
        'owedCollected': amount,
        'owedCollectionMethod': method,
        'owedCollectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      merge: true,
    );
  }

  /// Audit 2026-11-15 PW-21: the owed-collection state for one
  /// booking, so the return steps restore a collection recorded in
  /// an earlier session (mirroring [loadRefundState]). Absent (or
  /// unreadable) resolves to "not collected", never an error.
  static Future<({bool collected, int amount, String? method})>
      loadOwedState(String bookingId) async {
    try {
      final data = await sl<FirestoreService>()
          .getDocument('return_settlements', bookingId);
      if (data == null) return (collected: false, amount: 0, method: null);
      final amount = (data['owedCollected'] as num?)?.toInt() ?? 0;
      return (
        collected: amount > 0,
        amount: amount,
        method: data['owedCollectionMethod'] as String?,
      );
    } catch (_) {
      return (collected: false, amount: 0, method: null);
    }
  }
}
