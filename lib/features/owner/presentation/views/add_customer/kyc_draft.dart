import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

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
  XFile? licenseFrontPhoto;
  XFile? licenseBackPhoto;
  XFile? utilityBillPhoto;
  final List<XFile> extraPhotos = [];

  /// Signature pad PNG bytes (exported on Confirm). Null = unsigned.
  Uint8List? signaturePng;

  /// Terms checkbox on step 3.
  bool termsAgreed = false;

  bool get hasFacePhoto => facePhoto != null;
  bool get hasThumbprint => thumbprintPhoto != null;
  bool get hasLicenseFront => licenseFrontPhoto != null;
  bool get hasLicenseBack => licenseBackPhoto != null;
  bool get hasUtilityBill => utilityBillPhoto != null;
  bool get hasSignature =>
      signaturePng != null && signaturePng!.isNotEmpty;

  /// Step-4 completeness box (spec O15): CNIC, Photo, Thumb,
  /// License, Signature. Guarantor is not listed — it is optional.
  bool get isKycComplete =>
      cnic.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      hasFacePhoto &&
      hasThumbprint &&
      hasLicenseFront &&
      hasLicenseBack &&
      licenseNumber.trim().isNotEmpty &&
      hasUtilityBill &&
      hasSignature &&
      termsAgreed;
}
