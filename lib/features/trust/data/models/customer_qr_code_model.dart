import 'package:cloud_firestore/cloud_firestore.dart';

/// The CNIC back-QR number, stored apart from the customer record in
/// `customer_qr_codes/{customerId}`.
///
/// Firestore rules are document-level and cannot hide a single field,
/// so the number lives in this separate restricted document: only a
/// super admin may read it (see backend/firestore/firestore.rules).
/// The customer and owner apps write it at scan time and never read
/// or render it. It exists for manual legal verification with the
/// government later — it is a number, never parsed into name/CNIC
/// fields.
class CustomerQrCodeModel {
  static const String collection = 'customer_qr_codes';

  final String customerId;
  final String qrCode;
  final DateTime? updatedAt;

  const CustomerQrCodeModel({
    required this.customerId,
    required this.qrCode,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {'customerId': customerId, 'qrCode': qrCode};
  }

  factory CustomerQrCodeModel.fromMap(
      Map<String, dynamic> map, [
        String? id,
      ]) {
    final updated = map['updatedAt'];
    DateTime? updatedAt;
    if (updated is Timestamp) {
      updatedAt = updated.toDate();
    } else if (updated is String) {
      updatedAt = DateTime.tryParse(updated);
    }
    return CustomerQrCodeModel(
      customerId: id ?? (map['customerId'] as String? ?? ''),
      qrCode: (map['qrCode'] as String? ?? '').trim(),
      updatedAt: updatedAt,
    );
  }
}
