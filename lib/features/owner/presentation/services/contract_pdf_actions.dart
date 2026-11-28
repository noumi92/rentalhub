import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/signature_profile_service.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../handover/data/datasources/pdf_contract_generator.dart';
import 'contract_trip_charges.dart';

/// Audit item 17/18 (O20, O24): the agreement-PDF actions shared by
/// the contract view and the Agreement Signed screen — share, print,
/// and Download PDF (save to device). Download writes into the app
/// documents directory via `path_provider`, which is already a
/// dependency — no new package is needed. The guarantor signature
/// resolves lazily from Firestore: the booking's customer doc
/// carries `guarantorCustomerId`, and that customer's wizard-saved
/// `signatureUrl` is the signature — never invented; absent means
/// "pending", rendered honestly as such.
class ContractPdfActions {
  /// Shares the agreement PDF through the system share sheet — the
  /// user picks the app (e.g. WhatsApp or email). Nothing is sent
  /// automatically and nothing is claimed to have been sent.
  static Future<void> sharePdf({
    required BuildContext context,
    required String bookingId,
    required Uint8List? bytes,
    String? subject,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        files: [
          XFile.fromData(
            bytes,
            name: 'agreement-$bookingId.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        text: l10n.contractShareText(bookingId),
      ),
    );
  }

  /// Reads the explicit-agreement state off `agreements/{bookingId}`
  /// (merge-written by [saveAgreementState]): the "I agree" checkbox
  /// and the guarantor signature captured on the contract view.
  /// Anything unreadable resolves to "not agreed / not signed" —
  /// never an error and never an invented signature.
  static Future<({
    bool agreedToTerms,
    bool fullySigned,
    Uint8List? guarantorSignaturePng,
  })> loadAgreementState({required String bookingId}) async {
    try {
      final fs = FirebaseFirestore.instance;
      final doc = await fs.collection('agreements').doc(bookingId).get();
      final data = doc.data();
      if (data == null) {
        return (agreedToTerms: false, fullySigned: false, guarantorSignaturePng: null);
      }
      final b64 = data['guarantorSignatureB64'] as String?;
      return (
        agreedToTerms: data['agreedToTerms'] == true,
        fullySigned: data['fullySigned'] == true,
        guarantorSignaturePng:
            b64 != null && b64.isNotEmpty ? base64Decode(b64) : null,
      );
    } catch (_) {
      return (agreedToTerms: false, fullySigned: false, guarantorSignaturePng: null);
    }
  }

  /// Persists the explicit-agreement state on `agreements/{bookingId}`
  /// (merge — never clobbers the PDF URL, hash or status written at
  /// handover). Only the fields passed non-null are written. Returns
  /// false when the write failed so the caller can revert its UI.
  static Future<bool> saveAgreementState({
    required String bookingId,
    bool? agreedToTerms,
    Uint8List? guarantorSignaturePng,
    bool? fullySigned,
    Uint8List? agreementPdfB64,
  }) async {
    try {
      final fs = FirebaseFirestore.instance;
      final data = <String, dynamic>{
        'bookingId': bookingId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (agreedToTerms != null) data['agreedToTerms'] = agreedToTerms;
      if (guarantorSignaturePng != null) {
        data['guarantorSignatureB64'] = base64Encode(guarantorSignaturePng);
      }
      if (fullySigned != null) {
        data['fullySigned'] = fullySigned;
        if (fullySigned) data['signedAt'] = FieldValue.serverTimestamp();
      }
      if (agreementPdfB64 != null) {
        data['agreementPdfB64'] = base64Encode(agreementPdfB64);
      }
      await fs.collection('agreements').doc(bookingId).set(
            data,
            SetOptions(merge: true),
          );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> printPdf({
    required BuildContext context,
    required Uint8List? bytes,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Saves the agreement PDF to the app documents directory and
  /// reports the file name. Returns the saved path, or null when
  /// there was no PDF or the write failed.
  static Future<String?> downloadPdf({
    required BuildContext context,
    required String bookingId,
    required Uint8List? bytes,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return null;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/agreement-$bookingId.pdf');
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        AppFeedback.showSuccess(
            context, l10n.contractPdfDownloaded(file.path.split('/').last));
      }
      return file.path;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, l10n.contractPdfDownloadFailed(e.toString()));
      }
      return null;
    }
  }

  /// Item 10 (O47): regenerates the 1-page A4 PDF with all three
  /// signatures plus the guarantor detail block and the true photo
  /// count. Returns null when the handover odometer/fuel are
  /// unknown — the PDF cannot be regenerated honestly then. A
  /// failed vehicle lookup resolves to null rates, and the resolver
  /// omits the night-stay / tolls lines rather than printing
  /// defaults.
  static Future<Uint8List?> regenerateAgreementPdf({
    required BookingEntity booking,
    required int? odometer,
    required String? fuelLevel,
    required int? securityDeposit,
    required Uint8List? customerSignaturePng,
    required Uint8List? ownerSignaturePng,
    required Uint8List? guarantorSignaturePng,
    required List<String> damageNotes,
    required int? handoverPhotoCount,
  }) async {
    if (odometer == null || fuelLevel == null) return null;
    VehicleEntity? vehicle;
    try {
      if (sl.isRegistered<FleetRemoteDataSource>()) {
        vehicle = await sl<FleetRemoteDataSource>()
            .getVehicleById(booking.vehicleId);
      }
    } catch (_) {
      vehicle = null;
    }
    final charges = resolvePdfTripCharges(booking: booking, vehicle: vehicle);
    return PdfContractGenerator.generateA4Agreement(
      agreementId: booking.bookingId,
      shopName: booking.shopName ?? 'RentalHub',
      customerName: booking.customerName ?? '',
      cnicNumber: booking.customerCnic ?? '',
      customerPhone: booking.customerPhone ?? '',
      vehicleDetails: booking.vehicleName ?? '',
      packageType: booking.packageType,
      isWithDriver: booking.isWithDriver,
      pickupTime: booking.pickupTime,
      returnTime: booking.returnTime,
      totalAmount: booking.totalAmount,
      advancePaid: booking.advancePaid,
      securityDeposit: securityDeposit ?? 0,
      initialOdometer: odometer,
      fuelLevel: fuelLevel,
      damageNotes: damageNotes,
      customerSignaturePng: customerSignaturePng,
      ownerSignaturePng: ownerSignaturePng,
      guarantorSignaturePng: guarantorSignaturePng,
      guarantorName: booking.guarantorName,
      guarantorCnic: booking.guarantorCnic,
      guarantorRelation: booking.guarantorRelation,
      handoverPhotoCount: handoverPhotoCount,
      vehiclePlate: booking.vehiclePlate,
      tripType: charges.tripType,
      driverNightStayPkr: charges.driverNightStayPkr,
      tollsPaidBy: charges.tollsPaidBy,
    );
  }

  /// Item 10 (O48): opens a WhatsApp chat with the customer
  /// carrying the agreement verification link (manual send, same
  /// pattern as the dues reminder — no automated send, D2-gated).
  /// Returns false when there is no phone number or WhatsApp did
  /// not open, so the caller can say so instead of claiming a send.
  static Future<bool> sendVerificationToCustomer({
    required BuildContext context,
    required BookingEntity booking,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final phone = booking.customerPhone ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final number = digits.startsWith('92')
        ? digits
        : digits.startsWith('0')
            ? '92${digits.substring(1)}'
            : digits;
    if (number.isEmpty) {
      AppFeedback.showError(context, l10n.rentalStartedNoPhone);
      return false;
    }
    final url = PdfContractGenerator.verificationUrlFor(booking.bookingId);
    final message = l10n.agreementSignedSendMessage(
      booking.customerName ?? l10n.requestsCustomerFallback,
      url,
    );
    final uri = Uri.parse(
        'https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppFeedback.showError(context, l10n.rentalStartedWhatsappFailed);
    }
    return opened;
  }

  /// Item 10 (O46): the customer's driving-license number off
  /// `customers/{customerId}`, when one was recorded. Anything
  /// unreadable resolves to null — the row is omitted, never
  /// invented. Trust score is deliberately NOT resolved here: it is
  /// a live admin computation, not a field on the customer record.
  static Future<String?> resolveCustomerLicenseNumber({
    required String customerId,
  }) async {
    try {
      final fs = FirebaseFirestore.instance;
      final doc = await fs.collection('customers').doc(customerId).get();
      final license = doc.data()?['licenseNumber'] as String?;
      return license != null && license.isNotEmpty ? license : null;
    } catch (_) {
      return null;
    }
  }

  /// The wizard-saved signature of the booking's guarantor, if any.
  /// Returns (guarantorName, signatureUrl); either may be null.
  /// Firestore resolves lazily — without it the answer is "none",
  /// never an error and never a fabricated signature.
  static Future<({String? name, String? signatureUrl, Uint8List? signaturePng})>
      resolveGuarantorSignature({
    required String customerId,
    String? bookingGuarantorName,
  }) async {
    final loaded = await SignatureProfileService.loadGuarantorSignature(
      customerId,
      fallbackName: bookingGuarantorName,
    );
    return (
      name: loaded.name,
      signatureUrl: loaded.url,
      signaturePng: loaded.pngBytes,
    );
  }
}
