import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../../customer/domain/entities/customer_entity.dart';
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

  /// Walk-in CRM (edit mode): prefill every field from a saved
  /// record. Text fields copy straight across; media already on
  /// file lands in [existingUrls] (field name → stored URL) so the
  /// steps validate without re-capture and the saver keeps a URL
  /// unless the owner re-captures that slot. Terms are pre-agreed
  /// (the record was saved with them agreed). The CNIC back-QR
  /// number is NOT read back — it lives only in the restricted
  /// `customer_qr_codes/{customerId}` doc and is re-written only
  /// when a new back photo is scanned.
  KycDraft.fromEntity(CustomerEntity entity) {
    name = entity.name;
    fatherName = entity.fatherName ?? '';
    cnic = entity.cnic ?? '';
    dateOfBirth = entity.dateOfBirth ?? '';
    cnicExpiry = entity.cnicExpiry ?? '';
    address = entity.address ?? '';
    phone = entity.phone;
    licenseNumber = entity.licenseNumber ?? '';
    licenseExpiry = entity.licenseExpiry ?? '';
    guarantorCustomerId = entity.guarantorCustomerId;
    guarantorRelation = entity.guarantorRelation ?? 'Friend';
    guarantorName = entity.guarantorName ?? '';
    guarantorPhone = entity.guarantorPhone ?? '';
    guarantorCnic = entity.guarantorCnic ?? '';
    guarantorAddress = entity.guarantorAddress ?? '';
    termsAgreed = true;
    final urls = <String, String?>{
      'profilePhotoUrl': entity.profilePhotoUrl,
      'thumbprintUrl': entity.thumbprintUrl,
      'leftFingerprintUrl': entity.leftFingerprintUrl,
      'rightFingerprintUrl': entity.rightFingerprintUrl,
      'cnicFrontUrl': entity.cnicFrontUrl,
      'cnicBackUrl': entity.cnicBackUrl,
      'licenseFrontUrl': entity.licenseFrontUrl,
      'licenseBackUrl': entity.licenseBackUrl,
      'utilityBillUrl': entity.utilityBillUrl,
      'signatureUrl': entity.signatureUrl,
    };
    for (final entry in urls.entries) {
      final url = entry.value;
      if (url != null && url.isNotEmpty) existingUrls[entry.key] = url;
    }
    existingExtraDocumentUrls.addAll(entity.extraDocumentUrls);
  }

  /// Edit mode: URLs already on file, keyed by entity field name
  /// ('profilePhotoUrl', 'cnicFrontUrl', …). Empty in create mode.
  /// A slot counts as present when it has a new capture OR an
  /// on-file URL (see the [hasFacePhoto] family below); removing a
  /// photo in a step must also call [clearExisting] for that field,
  /// or the old URL would keep counting as present.
  final Map<String, String> existingUrls = {};

  /// Edit mode: extra documents already on file. New captures go
  /// in [extraPhotos]; these are preserved as-is by the saver.
  final List<String> existingExtraDocumentUrls = [];

  String? existingUrlFor(String field) => existingUrls[field];

  /// Drops the on-file URL for [field] (owner removed the photo in
  /// a step); a save after this writes no URL for the slot.
  void clearExisting(String field) => existingUrls.remove(field);

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

  // Step 3 — guarantor (optional: existing customer OR inline details).
  String? guarantorCustomerId;
  String guarantorRelation = 'Friend';
  String guarantorName = '';
  String guarantorPhone = '';
  String guarantorCnic = '';
  String guarantorAddress = '';

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

  /// Each getter is true when the slot has a fresh capture OR an
  /// on-file URL (edit mode). In create mode [existingUrls] is
  /// empty, so these behave exactly as before.
  bool get hasFacePhoto =>
      facePhoto != null || existingUrls.containsKey('profilePhotoUrl');
  bool get hasThumbprint =>
      thumbprintPhoto != null || existingUrls.containsKey('thumbprintUrl');
  bool get hasLeftFingerprints =>
      leftFingersPhoto != null ||
      existingUrls.containsKey('leftFingerprintUrl');
  bool get hasRightFingerprints =>
      rightFingersPhoto != null ||
      existingUrls.containsKey('rightFingerprintUrl');
  bool get hasLicenseFront =>
      licenseFrontPhoto != null ||
      existingUrls.containsKey('licenseFrontUrl');
  bool get hasLicenseBack =>
      licenseBackPhoto != null ||
      existingUrls.containsKey('licenseBackUrl');
  bool get hasUtilityBill =>
      utilityBillPhoto != null || existingUrls.containsKey('utilityBillUrl');
  bool get hasSignature =>
      (signaturePng != null && signaturePng!.isNotEmpty) ||
      existingUrls.containsKey('signatureUrl');

  bool get hasCnicFront =>
      cnicFrontPhoto != null || existingUrls.containsKey('cnicFrontUrl');
  bool get hasCnicBack =>
      cnicBackPhoto != null || existingUrls.containsKey('cnicBackUrl');
  bool get hasGuarantor =>
      (guarantorCustomerId != null && guarantorCustomerId!.trim().isNotEmpty) ||
      guarantorName.trim().isNotEmpty;

  /// KYC completeness: strictly CNIC (front + back) & Driving License
  /// (front + back) + customer name & CNIC number. Guarantor is optional.
  bool get isKycComplete =>
      cnic.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      hasCnicFront &&
      hasCnicBack &&
      hasLicenseFront &&
      hasLicenseBack;
}
