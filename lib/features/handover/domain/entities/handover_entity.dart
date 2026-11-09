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

  /// Audit item 4 (O19 1/2 + 2/2): the exterior photos taken at
  /// handover, the documents handed to the customer, the accessories
  /// in the car, and whether the keys were handed over. All four
  /// photo URLs are cPanel signed URLs (or null when not taken);
  /// nothing here is ever a demo value.
  final String? photoFrontUrl;
  final String? photoBackUrl;
  final String? photoLeftUrl;
  final String? photoRightUrl;
  final List<String> documentsGiven; // 'registration' | 'insurance'
  final List<String> accessories; // 'spare_tyre' | 'jack' | 'tool_kit'
  final bool keysHandedOver;

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
    this.photoFrontUrl,
    this.photoBackUrl,
    this.photoLeftUrl,
    this.photoRightUrl,
    this.documentsGiven = const [],
    this.accessories = const [],
    this.keysHandedOver = false,
  });

  HandoverEntity copyWith({
    String? agreementPdfUrl,
    bool? isSynced,
    String? agreementPdfB64,
    String? photoFrontUrl,
    String? photoBackUrl,
    String? photoLeftUrl,
    String? photoRightUrl,
    List<String>? documentsGiven,
    List<String>? accessories,
    bool? keysHandedOver,
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
      photoFrontUrl: photoFrontUrl ?? this.photoFrontUrl,
      photoBackUrl: photoBackUrl ?? this.photoBackUrl,
      photoLeftUrl: photoLeftUrl ?? this.photoLeftUrl,
      photoRightUrl: photoRightUrl ?? this.photoRightUrl,
      documentsGiven: documentsGiven ?? this.documentsGiven,
      accessories: accessories ?? this.accessories,
      keysHandedOver: keysHandedOver ?? this.keysHandedOver,
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
        photoFrontUrl,
        photoBackUrl,
        photoLeftUrl,
        photoRightUrl,
        documentsGiven,
        accessories,
        keysHandedOver,
      ];
}
