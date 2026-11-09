import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/usecases/save_customer_usecase.dart';
import '../../../customer/utils/save_walk_in_customer.dart';
import '../../../../core/di/injection_container.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../views/add_customer/kyc_draft.dart';
import 'kyc_media_upload_service.dart';

/// What [KycCustomerSaver.save] produced.
class KycSaveResult {
  /// The saved record (URLs only for files uploaded right now;
  /// queued fields are left off — the queue handler writes them
  /// when the device is back online).
  final CustomerEntity customer;

  /// Files that were queued instead of uploaded (offline).
  final int queuedPhotos;

  /// Optional extra documents that could not be uploaded (and could
  /// not be queued — the queue handler cannot append to a list).
  /// They are skipped, never faked; the caller says so honestly.
  final int skippedExtraDocs;

  const KycSaveResult({
    required this.customer,
    required this.queuedPhotos,
    required this.skippedExtraDocs,
  });
}

/// The wizard's single save (step 4): blacklist re-check → upload
/// the KYC media → build the full [CustomerEntity] → write it once
/// through the existing [SaveCustomerUseCase] (Firestore `customers`
/// merge set + server timestamp, offline queue fallback).
///
/// No face matching happens here and no `is_verified` is set — the
/// customer stays unverified until an admin reviews the saved face
/// photo and documents manually.
///
/// A failed upload of a REQUIRED file aborts the save (the error
/// names the file) — a save is never reported as succeeded when its
/// files are missing. Dependencies are injectable so tests can pass
/// fakes instead of the service locator.
class KycCustomerSaver {
  final SaveCustomerUseCase _saveUseCase;
  final BlacklistRemoteDataSource _blacklist;
  final KycMediaUploadService _uploader;

  KycCustomerSaver({
    SaveCustomerUseCase? saveUseCase,
    BlacklistRemoteDataSource? blacklist,
    KycMediaUploadService? uploader,
  })  : _saveUseCase = saveUseCase ?? sl<SaveCustomerUseCase>(),
        _blacklist = blacklist ?? sl<BlacklistRemoteDataSource>(),
        _uploader = uploader ?? sl<KycMediaUploadService>();

  Future<KycSaveResult> save({
    required String shopId,
    required KycDraft draft,
  }) async {
    // Step 1 already checked, but the CNIC may have been edited
    // since, or listed in between — refuse again, the same way the
    // walk-in path refuses (never a NADRA claim).
    if (await _blacklist.isCnicBlacklisted(draft.cnic)) {
      throw BlacklistedCustomerException(draft.cnic);
    }
    final digits = draft.cnic.replaceAll(RegExp(r'\D'), '');
    final customerId = digits.isNotEmpty
        ? 'cust-$digits'
        : 'cust-${DateTime.now().millisecondsSinceEpoch}';

    final uploads = await _uploader.uploadAll(
      shopId: shopId,
      customerId: customerId,
      draft: draft,
    );
    // A failed REQUIRED upload aborts the save — the record must
    // never claim files it does not have.
    final requiredFailed = uploads.failedFields
        .where((f) => !f.startsWith('extraDocumentUrls_'))
        .toList();
    if (requiredFailed.isNotEmpty) {
      throw StateError('Upload failed for: ${requiredFailed.join(', ')}');
    }
    final skippedExtra = uploads.failedFields
        .where((f) => f.startsWith('extraDocumentUrls_'))
        .length;

    final extraUrls = <String>[];
    for (var i = 0; i < draft.extraPhotos.length; i++) {
      final url = uploads.urls['extraDocumentUrls_$i'];
      if (url != null) extraUrls.add(url);
    }
    final customer = CustomerEntity(
      customerId: customerId,
      shopId: shopId,
      name: draft.name.trim(),
      phone: draft.phone.trim(),
      cnic: draft.cnic.trim().isEmpty ? null : draft.cnic.trim(),
      source: 'walk_in',
      createdAt: DateTime.now(),
      dateOfBirth: _orNull(draft.dateOfBirth),
      cnicExpiry: _orNull(draft.cnicExpiry),
      fatherName: _orNull(draft.fatherName),
      address: _orNull(draft.address),
      profilePhotoUrl: uploads.urls['profilePhotoUrl'],
      thumbprintUrl: uploads.urls['thumbprintUrl'],
      cnicFrontUrl: uploads.urls['cnicFrontUrl'],
      cnicBackUrl: uploads.urls['cnicBackUrl'],
      licenseNumber: _orNull(draft.licenseNumber),
      licenseExpiry: _orNull(draft.licenseExpiry),
      licenseFrontUrl: uploads.urls['licenseFrontUrl'],
      licenseBackUrl: uploads.urls['licenseBackUrl'],
      utilityBillUrl: uploads.urls['utilityBillUrl'],
      extraDocumentUrls: extraUrls,
      signatureUrl: uploads.urls['signatureUrl'],
      guarantorCustomerId: draft.guarantorCustomerId,
      guarantorRelation:
          draft.guarantorCustomerId == null ? null : draft.guarantorRelation,
    );
    await _saveUseCase(customer);
    return KycSaveResult(
      customer: customer,
      queuedPhotos: uploads.queuedCount,
      skippedExtraDocs: skippedExtra,
    );
  }

  static String? _orNull(String value) =>
      value.trim().isEmpty ? null : value.trim();
}
