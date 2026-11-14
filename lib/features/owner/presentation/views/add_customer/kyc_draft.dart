import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../../trust/utils/cnic_text_parser.dart';
import '../../../../trust/utils/license_document_parser.dart';

/// Mutable draft for the Add Customer wizard (O12–O15). The shell
/// owns one instance for the whole wizard; steps read/write it and
/// notify the shell (via [onChanged]) so the stepper, the Next/Save
/// enablement and the step-4 completeness box stay in sync.
///
/// Nothing here is saved until step 4: the wizard writes once
/// through [KycCustomerSaver]. No face matching happens anywhere —
/// the face photo is saved and an admin reviews it manually.
class KycDraft {
  KycDraft({String? prefilledCnic}) : cnic = prefilledCnic ?? '';

  // Step 1 — CNIC + identity (all editable by hand; scan prefills).
  String name = '';
  String fatherName = '';
  String cnic = '';
  String dateOfBirth = '';
  String cnicExpiry = '';
  String address = '';
  String phone = '';

  /// The CNIC back-QR NUMBER, read at scan time. Stored only in the
  /// restricted `customer_qr_codes/{customerId}` doc (super admin
  /// only) — never on the customer record, never rendered in the
  /// owner or customer apps.
  String qrCode = '';

  // Step 3 — driving license.
  String licenseNumber = '';
  String licenseExpiry = '';

  // Step 4 — guarantor (optional).
  String? guarantorCustomerId;
  String guarantorRelation = 'Friend';

  // Media, picked with the camera/gallery. Null = not captured yet.
  XFile? cnicFrontPhoto;
  XFile? cnicBackPhoto;
  XFile? facePhoto;
  XFile? thumbprintPhoto;

  /// Fingerprint photos — one photo per hand showing the 4 fingers
  /// (index/middle/ring/little), taken with the REAR camera. Photos,
  /// never scans: no fingerprint SDK is in the app. Null = not
  /// captured yet.
  XFile? leftFingersPhoto;
  XFile? rightFingersPhoto;
  XFile? licenseFrontPhoto;
  XFile? licenseBackPhoto;
  XFile? utilityBillPhoto;
  final List<XFile> extraPhotos = [];

  /// Signature pad PNG bytes (exported on Confirm). Null = unsigned.
  Uint8List? signaturePng;

  /// Terms checkbox on step 3.
  bool termsAgreed = false;

  /// Applies a CNIC OCR result to the draft fields (non-null values
  /// only). The step mirrors the same values into its controllers.
  void applyCnicScan(CnicScanResult result) {
    if (result.name != null) name = result.name!;
    if (result.fatherName != null) fatherName = result.fatherName!;
    if (result.cnicNumber != null) cnic = result.cnicNumber!;
    if (result.dateOfBirth != null) dateOfBirth = result.dateOfBirth!;
    if (result.dateOfExpiry != null) cnicExpiry = result.dateOfExpiry!;
    if (result.address != null) address = result.address!;
  }

  /// Applies a driving-license OCR result to the draft fields
  /// (non-null values only). The front capture overwrites; the back
  /// capture only fills fields the front did not yield.
  void applyLicenseScan(LicenseScanResult result, {bool overwrite = true}) {
    if (result.licenseNumber != null &&
        (overwrite || licenseNumber.isEmpty)) {
      licenseNumber = result.licenseNumber!;
    }
    if (result.dateOfExpiry != null &&
        (overwrite || licenseExpiry.isEmpty)) {
      licenseExpiry = result.dateOfExpiry!;
    }
  }

  bool get hasFacePhoto => facePhoto != null;
  bool get hasThumbprint => thumbprintPhoto != null;
  bool get hasLeftFingerprints => leftFingersPhoto != null;
  bool get hasRightFingerprints => rightFingersPhoto != null;
  bool get hasLicenseFront => licenseFrontPhoto != null;
  bool get hasLicenseBack => licenseBackPhoto != null;
  bool get hasUtilityBill => utilityBillPhoto != null;
  bool get hasSignature =>
      signaturePng != null && signaturePng!.isNotEmpty;

  /// Step-4 completeness box (spec O15): CNIC, Photo, Fingerprints,
  /// License, Signature. Guarantor is not listed — it is optional.
  /// Fingerprints means both hand photos captured (left + right,
  /// 4 fingers each); the old single thumbprint photo is no longer
  /// captured in step 2.
  bool get isKycComplete =>
      cnic.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      hasFacePhoto &&
      hasLeftFingerprints &&
      hasRightFingerprints &&
      hasLicenseFront &&
      hasLicenseBack &&
      licenseNumber.trim().isNotEmpty &&
      hasUtilityBill &&
      hasSignature &&
      termsAgreed;
}
