import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../trust/data/services/cnic_ocr_service.dart';
import '../../../trust/data/services/document_qr_service.dart';
import 'kyc_media_upload_service.dart';

/// Walk-in CRM (KYC replace): recaptures ONE KYC slot for a
/// walk-in customer and uploads it to the cPanel `kyc` folder.
///
/// Picker rules are the wizard's (see [Step1Cnic._pickCnic] and
/// [Step3Docs._pick]): CNIC front/back may come from the gallery,
/// but a gallery photo is OCR-scanned first and REJECTED when
/// nothing can be read from it; every other slot is rear-camera
/// only (the signature slot is a camera photo of the signature —
/// the pad lives in the wizard, not on the detail screen).
/// Nothing is re-parsed into identity fields: a replaced CNIC
/// photo never changes the CNIC number (the record key), and a
/// replaced license photo never changes the license number.
class KycSlotReplaceException implements Exception {
  /// True when a gallery CNIC photo was rejected as unreadable
  /// (the caller shows the "not clear enough" copy); false for a
  /// plain upload failure.
  final bool unreadable;

  const KycSlotReplaceException({required this.unreadable});
}

class KycSlotReplaceService {
  final ImagePicker _picker;
  final CnicOcrService _ocrService;
  final DocumentQrService _qrService;
  final KycMediaUploadService _uploader;

  KycSlotReplaceService({
    ImagePicker? picker,
    CnicOcrService? ocrService,
    DocumentQrService? qrService,
    KycMediaUploadService? uploader,
  })  : _picker = picker ?? ImagePicker(),
        _ocrService = ocrService ?? CnicOcrService(),
        _qrService = qrService ?? DocumentQrService(),
        _uploader = uploader ?? sl<KycMediaUploadService>();

  static bool isCnicSlot(String field) =>
      field == 'cnicFrontUrl' || field == 'cnicBackUrl';

  /// Picks, guards and uploads one slot. Returns the signed URL,
  /// or null when the owner cancelled the pick (no error — the
  /// caller stays silent). Throws [KycSlotReplaceException] when
  /// the pick was rejected (unreadable gallery CNIC) or the upload
  /// failed.
  Future<String?> replaceSlot({
    required CustomerEntity customer,
    required String field,
    required String shopId,
    required bool fromGallery,
  }) async {
    final picked = await _picker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (picked == null) return null;
    if (fromGallery && isCnicSlot(field)) {
      // Gallery guard (same rule as the wizard): the photo must
      // yield something readable or it is rejected. The scan
      // result is deliberately NOT applied to the record — no
      // re-parsing of identity fields from a replacement photo.
      final front = field == 'cnicFrontUrl';
      bool readable;
      if (front) {
        final result = await _ocrService.scanFront(File(picked.path));
        readable = result.hasAnything;
      } else {
        final code = await _qrService.readQr(File(picked.path));
        var ocrReadable = false;
        try {
          final ocr = await _ocrService.scanBack(File(picked.path));
          ocrReadable = ocr.hasAnything;
        } catch (_) {
          ocrReadable = false;
        }
        readable =
            (code != null && code.isNotEmpty) || ocrReadable;
      }
      if (!readable) {
        throw const KycSlotReplaceException(unreadable: true);
      }
    }
    final url = await _uploader.uploadSingle(
      shopId: shopId,
      customerId: customer.customerId,
      field: field,
      file: picked,
    );
    if (url == null) {
      throw const KycSlotReplaceException(unreadable: false);
    }
    return url;
  }
}
