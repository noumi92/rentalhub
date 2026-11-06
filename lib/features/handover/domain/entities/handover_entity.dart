import 'package:equatable/equatable.dart';

class HandoverEntity extends Equatable {
  final String bookingId;
  final int initialOdometer;
  final String fuelLevel; // e.g., '6/8 (75%)'
  final List<String> damageNotes;
  final String customerSignatureSvg;
  final String ownerSignatureSvg;
  final String? agreementPdfUrl;
  final bool isSynced;

  /// Phase B (E2/E3): the real signature PNGs (base64) drawn on the
  /// pads, and the generated A4 PDF itself (base64) while it waits
  /// to sync. The old SVG fields are kept only so offline records
  /// saved before this phase still read back.
  final String? customerSignatureB64;
  final String? ownerSignatureB64;
  final String? agreementPdfB64;

  /// Phase B (E3): the agreement metadata the verify page and the
  /// `agreements` Firestore doc need. Kept on the record so a
  /// handover completed offline can still sync later.
  final String? shopId;
  final String? shopName;
  final String? customerName;
  final String? cnicNumber;
  final String? vehicleDetails;
  final int? totalAmount;

  const HandoverEntity({
    required this.bookingId,
    required this.initialOdometer,
    required this.fuelLevel,
    this.damageNotes = const [],
    required this.customerSignatureSvg,
    required this.ownerSignatureSvg,
    this.agreementPdfUrl,
    this.isSynced = false,
    this.customerSignatureB64,
    this.ownerSignatureB64,
    this.agreementPdfB64,
    this.shopId,
    this.shopName,
    this.customerName,
    this.cnicNumber,
    this.vehicleDetails,
    this.totalAmount,
  });

  HandoverEntity copyWith({
    String? agreementPdfUrl,
    bool? isSynced,
    String? agreementPdfB64,
  }) {
    return HandoverEntity(
      bookingId: bookingId,
      initialOdometer: initialOdometer,
      fuelLevel: fuelLevel,
      damageNotes: damageNotes,
      customerSignatureSvg: customerSignatureSvg,
      ownerSignatureSvg: ownerSignatureSvg,
      agreementPdfUrl: agreementPdfUrl ?? this.agreementPdfUrl,
      isSynced: isSynced ?? this.isSynced,
      customerSignatureB64: customerSignatureB64,
      ownerSignatureB64: ownerSignatureB64,
      agreementPdfB64: agreementPdfB64 ?? this.agreementPdfB64,
      shopId: shopId,
      shopName: shopName,
      customerName: customerName,
      cnicNumber: cnicNumber,
      vehicleDetails: vehicleDetails,
      totalAmount: totalAmount,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        initialOdometer,
        fuelLevel,
        damageNotes,
        customerSignatureSvg,
        ownerSignatureSvg,
        agreementPdfUrl,
        isSynced,
        customerSignatureB64,
        ownerSignatureB64,
        agreementPdfB64,
        shopId,
        shopName,
        customerName,
        cnicNumber,
        vehicleDetails,
        totalAmount,
      ];
}

