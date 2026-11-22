import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/di/injection_container.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../handover/domain/entities/handover_entity.dart';
import '../../../handover/presentation/cubit/handover_cubit.dart';
import '../../../handover/presentation/cubit/handover_wizard_cubit.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';

/// Item 9 (O30): the wizard's finalize, extracted so the shell
/// stays under the 250-line cap.
///
/// Exports the signatures (saved or fresh), completes the
/// handover through [HandoverCubit] (PDF + offline save + sync),
/// flips the booking to `active`, and returns the finished entity
/// + PDF bytes for the completion card's Share PDF. Throws on
/// failure; the shell reports it. The trip starts at certify time
/// — the trip timer on Rental Started counts from
/// [HandoverEntity.tripStartAt].
class HandoverWizardFinalize {
  static Future<({HandoverEntity entity, Uint8List? pdfBytes})> run({
    required BookingEntity booking,
    required String shopName,
    required int securityDeposit,
    required String? vehiclePlate,
    required String? vehicleColour,
    required String? vehicleFuel,
    required HandoverWizardCubit wizard,
    required String customerNameFallback,
    required String vehicleFallback,
    required bool isOnline,
  }) async {
    final state = wizard.state;
    final sigs = await wizard.exportSignatures();
    final now = DateTime.now();
    final entity = await sl<HandoverCubit>().completeHandoverOfflineFirst(
      bookingId: booking.bookingId,
      shopId: booking.shopId,
      shopName: shopName,
      customerName: booking.customerName ?? customerNameFallback,
      customerId: booking.customerId,
      customerPhone: booking.customerPhone ?? '',
      cnicNumber: booking.customerCnic ?? 'Not provided',
      vehicleDetails: booking.vehicleName ?? vehicleFallback,
      packageType: booking.packageType,
      isWithDriver: booking.isWithDriver,
      pickupTime: booking.pickupTime,
      returnTime: booking.returnTime,
      totalAmount: booking.totalAmount,
      advancePaid: booking.advancePaid,
      securityDeposit: securityDeposit,
      balanceDuePkr:
          (booking.totalAmount - booking.advancePaid).clamp(0, 1 << 30),
      balancePaymentMethod: state.balanceMethod,
      balanceReceived: state.balanceReceived,
      depositReceived: state.depositReceived,
      vehicleId: booking.vehicleId,
      initialOdometer: state.odometer,
      fuelLevel: state.fuelLevel,
      damageNotes: state.damageNotes,
      photoFrontUrl: state.photos['front'],
      photoBackUrl: state.photos['back'],
      photoLeftUrl: state.photos['left'],
      photoRightUrl: state.photos['right'],
      photoInteriorUrl: state.photos['interior'],
      photoDashboardUrl: state.photos['dashboard'],
      photoTakenAt: state.photoTakenAt,
      damagePins: state.damagePins
          .map((p) => HandoverDamagePin(zone: p.zone, type: p.type))
          .toList(),
      documentsGiven: state.documentsGiven.toList(),
      accessories: state.accessories.toList(),
      keysHandedOver: state.keysHandedOver,
      faceCheckConfirmed: state.faceCheckConfirmed,
      faceCheckedAt: state.faceCheckedAt,
      depositPaymentMethod: state.depositMethod,
      depositReceivedAt: state.depositReceivedAt,
      receiptId: state.receiptId,
      acWorking: state.acWorking,
      lightsWorking: state.lightsWorking,
      tripStartAt: now,
      wizardCompletedAt: now,
      customerSignatureSource: wizard.customerSignatureSource,
      ownerSignatureSource: wizard.ownerSignatureSource,
      vehiclePlate: vehiclePlate,
      vehicleColour: vehicleColour,
      vehicleFuel: vehicleFuel,
      guarantorName: booking.guarantorName,
      guarantorCnic: booking.guarantorCnic,
      guarantorRelation: booking.guarantorRelation,
      customerSignaturePng: sigs.customer,
      ownerSignaturePng: sigs.owner,
      isOnline: isOnline,
    );
    await sl<BookingRemoteDataSource>().updateBookingStatus(
        bookingId: booking.bookingId, status: 'active');
    if (booking.origin != 'walk_in' &&
        booking.customerId.isNotEmpty &&
        !booking.customerId.startsWith('walkin-') &&
        sl.isRegistered<NotificationDataSource>()) {
      try {
        await sl<NotificationDataSource>().createCustomerNotification(
          customerId: booking.customerId,
          shopId: booking.shopId,
          title: 'Trip started — Agreement ready',
          body:
              'Your rental of ${booking.vehicleName ?? vehicleFallback} at $shopName is now active.',
          type: 'handover',
          bookingId: booking.bookingId,
        );
      } catch (_) {}
    }
    final pdfBytes = entity.agreementPdfB64 == null
        ? null
        : base64Decode(entity.agreementPdfB64!);
    return (entity: entity, pdfBytes: pdfBytes);
  }
}
