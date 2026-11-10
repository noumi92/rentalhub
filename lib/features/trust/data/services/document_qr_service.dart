import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The image-to-QR decoder, injectable so tests can pass a fake
/// instead of the real scanner.
typedef QrImageAnalyzer = Future<String?> Function(String path);

/// Reads the QR code off a captured card photo with ML Kit barcode
/// scanning (via `mobile_scanner`, already a direct dependency and
/// already used for the booking QR scan — no new package needed;
/// `google_mlkit_barcode_scanning` is NOT in pubspec.yaml).
///
/// The decoded payload is returned raw: the CNIC back QR holds a
/// NUMBER that is stored as-is in the dedicated `qrCode` field
/// (restricted document `customer_qr_codes/{customerId}`), never
/// parsed into name/CNIC fields.
class DocumentQrService {
  final QrImageAnalyzer _analyze;

  DocumentQrService({QrImageAnalyzer? analyzeImage})
      : _analyze = analyzeImage ?? _defaultAnalyze;

  static Future<String?> _defaultAnalyze(String path) async {
    final controller = MobileScannerController();
    try {
      final capture = await controller.analyzeImage(
        path,
        formats: const [BarcodeFormat.qrCode],
      );
      final barcodes = capture?.barcodes ?? const <Barcode>[];
      final raw = barcodes.isNotEmpty
          ? barcodes.first.rawValue?.trim()
          : null;
      return (raw == null || raw.isEmpty) ? null : raw;
    } finally {
      await controller.dispose();
    }
  }

  /// Best-effort: null when there is no QR code on the photo or the
  /// scanner fails. Callers fall back to OCR and never fail the
  /// capture because the QR could not be read.
  Future<String?> readQr(File image) async {
    try {
      return await _analyze(image.path);
    } catch (e) {
      debugPrint('QR read failed: $e');
      return null;
    }
  }
}
