import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/signature_profile_service.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../../core/utils/shop_name.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../handover/presentation/cubit/handover_wizard_cubit.dart';

/// Item 9 (O26–O30): the wizard shell's data load, extracted so
/// the shell stays under the 250-line cap.
///
/// Loads the shop name + the vehicle's per-vehicle deposit and
/// detail (the deposit is `securityDepositPkr` — never hardcoded),
/// the customer's KYC photo (O26 face check) + saved signature
/// (O30, spec O21 "Saved signature auto-applied"), and the owner's
/// on-file signature from the shop record. Nothing here invents a
/// value: a missing shop field or a failed fetch leaves the
/// signature absent, and the wizard falls back to the fresh pad.
class HandoverWizardLoader {
  /// `firestore` is injectable for tests; production callers omit
  /// it and the default `FirebaseFirestore.instance` is used.
  static Future<({
    String shopName,
    int securityDeposit,
    int extraHourPkr,
    String? vehiclePlate,
    String? vehicleColour,
    String? vehicleFuel,
    String? kycPhotoUrl,
  })> load({
    required BookingEntity booking,
    required HandoverWizardCubit wizard,
    FirebaseFirestore? firestore,
  }) async {
    var shopName = booking.shopName ?? '';
    var securityDeposit = 0;
    var extraHourPkr = 0;
    String? vehiclePlate;
    String? vehicleColour;
    String? vehicleFuel;
    String? kycPhotoUrl;
    final shopId = booking.shopId;
    final fs = firestore ?? FirebaseFirestore.instance;
    if (shopId.isNotEmpty) {
      // Always read the shop doc so the owner's saved signature loads
      // even when booking.shopName is already populated.
      final doc = await fs
          .collection('shops')
          .doc(await canonicalShopId(fs, shopId))
          .get();
      if (shopName.isEmpty) {
        final name = shopNameFromData(doc.data());
        if (name.isNotEmpty) shopName = name;
      }
      // O30: the owner's on-file signature, if the shop record
      // carries one (no such field exists on shops today — the
      // lookup is honest: absent means "sign fresh on the pad").
      final ownerSigUrl = (doc.data()?['ownerSignatureUrl'] ??
          doc.data()?['signatureUrl']) as String?;
      final ownerSigB64 = doc.data()?['ownerSignatureB64'] as String?;
      Uint8List? ownerPng;
      if (ownerSigB64 != null && ownerSigB64.isNotEmpty) {
        try {
          ownerPng = base64Decode(ownerSigB64);
        } catch (_) {}
      } else if (ownerSigUrl != null && ownerSigUrl.isNotEmpty) {
        ownerPng = await _fetchImageBytes(ownerSigUrl);
      }
      if ((ownerSigUrl != null && ownerSigUrl.isNotEmpty) ||
          ownerPng != null) {
        wizard.setOwnerSavedSignature(url: ownerSigUrl, pngBytes: ownerPng);
      }
    }
    final vehicles =
        await sl<FleetRemoteDataSource>().getShopVehicles(shopId);
    final vehicle = vehicles
        .where((v) => v.vehicleId == booking.vehicleId)
        .toList();
    if (vehicle.isNotEmpty) {
      securityDeposit = vehicle.first.securityDepositPkr ?? 0;
      extraHourPkr = vehicle.first.extraHourPkr ?? 0;
      vehiclePlate = vehicle.first.plateNumber;
      vehicleColour = vehicle.first.color;
      vehicleFuel = vehicle.first.fuelType;
      final mileage = vehicle.first.mileageKm;
      if (mileage != null && mileage > 0 && wizard.state.odometer == 0) {
        wizard.setOdometer(mileage);
      }
    }
    // O26/O30: the customer's KYC photo (face check) + saved
    // signature (checks both `signatureB64` and `signatureUrl`).
    try {
      final customer = await sl<CustomerRemoteDataSource>()
          .getCustomerById(booking.customerId);
      if (customer != null) {
        kycPhotoUrl = customer.profilePhotoUrl;
      }
      final savedSig = await SignatureProfileService.loadCustomerSignature(
        booking.customerId,
        firestore: fs,
      );
      if (savedSig.pngBytes != null ||
          (savedSig.url != null && savedSig.url!.isNotEmpty)) {
        wizard.setCustomerSavedSignature(
          url: savedSig.url,
          pngBytes: savedSig.pngBytes,
        );
      }
      final gSig = await SignatureProfileService.loadGuarantorSignature(
        booking.customerId,
        fallbackName: booking.guarantorName,
        firestore: fs,
      );
      if (gSig.pngBytes != null || (gSig.url != null && gSig.url!.isNotEmpty)) {
        wizard.setGuarantorSavedSignature(
          url: gSig.url,
          pngBytes: gSig.pngBytes,
        );
      }
    } catch (_) {}
    return (
      shopName: shopName,
      securityDeposit: securityDeposit,
      extraHourPkr: extraHourPkr,
      vehiclePlate: vehiclePlate,
      vehicleColour: vehicleColour,
      vehicleFuel: vehicleFuel,
      kycPhotoUrl: kycPhotoUrl,
    );
  }

  static Future<Uint8List?> _fetchImageBytes(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.bodyBytes.length < 8) return null;
      // A PNG starts with the 8-byte PNG signature; the PDF
      // generator only embeds real PNGs, so anything else is not a
      // usable saved signature (the URL can still display on file).
      const pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      for (var i = 0; i < pngMagic.length; i++) {
        if (res.bodyBytes[i] != pngMagic[i]) return null;
      }
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }
}
