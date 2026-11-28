import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/signature_profile_service.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../handover/domain/entities/handover_entity.dart';
import '../../../handover/presentation/cubit/handover_cubit.dart';
import '../../../handover/presentation/cubit/handover_wizard_cubit.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import 'contract_pdf_actions.dart';

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
    int extraHourPkr = 0,
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
    final remainingBeforeHandover =
        (booking.totalAmount - booking.advancePaid).clamp(0, 1 << 30);
    final collectedAtHandover =
        state.cashReceivedAtHandover.clamp(0, remainingBeforeHandover);
    final includeGuarantor = !state.guarantorOptedOut;
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
      extraHourPkr: extraHourPkr,
      cashReceivedAtHandover: collectedAtHandover,
      balanceDuePkr: collectedAtHandover > 0
          ? collectedAtHandover
          : remainingBeforeHandover,
      balancePaymentMethod: state.balanceMethod,
      balanceReceived: collectedAtHandover > 0,
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
      guarantorName: includeGuarantor ? booking.guarantorName : null,
      guarantorCnic: includeGuarantor ? booking.guarantorCnic : null,
      guarantorRelation: includeGuarantor ? booking.guarantorRelation : null,
      customerSignaturePng: sigs.customer,
      ownerSignaturePng: sigs.owner,
      guarantorSignaturePng: includeGuarantor ? sigs.guarantor : null,
      isOnline: isOnline,
    );
    final pdfBytes = entity.agreementPdfB64 == null
        ? null
        : base64Decode(entity.agreementPdfB64!);
    // Finalize agreement state BEFORE activating the trip.
    await ContractPdfActions.saveAgreementState(
      bookingId: booking.bookingId,
      agreedToTerms: true,
      fullySigned: true,
      guarantorSignaturePng: includeGuarantor ? sigs.guarantor : null,
      agreementPdfB64: pdfBytes,
    );
    await sl<BookingRemoteDataSource>().updateBookingStatus(
        bookingId: booking.bookingId, status: 'active');
    // Persist freshly drawn signatures to customer, owner & guarantor profiles.
    if (sigs.customer != null && wizard.customerSignatureSource == 'fresh') {
      await SignatureProfileService.saveCustomerSignature(
          booking.customerId, sigs.customer!);
    }
    if (sigs.owner != null && wizard.ownerSignatureSource == 'fresh') {
      await SignatureProfileService.saveOwnerSignature(
          booking.shopId, sigs.owner!);
    }
    if (includeGuarantor &&
        sigs.guarantor != null &&
        wizard.guarantorSignatureSource == 'fresh') {
      await SignatureProfileService.saveGuarantorSignature(
          booking.customerId, sigs.guarantor!);
    }
    if (state.odometer > 0 && sl.isRegistered<FleetRemoteDataSource>()) {
      try {
        await sl<FleetRemoteDataSource>().updateVehicleMileage(
            vehicleId: booking.vehicleId, mileageKm: state.odometer);
      } catch (_) {}
    }
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
    return (entity: entity, pdfBytes: pdfBytes);
  }
}
