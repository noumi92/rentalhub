import 'package:equatable/equatable.dart';

/// One damage pin placed on the handover car diagram (O29): the
/// zone tapped plus the damage type recorded for it. Stored as a
/// plain value (not the return-side [DamagePin] widget type) so the
/// entity stays UI-free and round-trips through JSON / Firestore.
class HandoverDamagePin extends Equatable {
  final String zone;
  final String type;

  const HandoverDamagePin({required this.zone, required this.type});

  Map<String, dynamic> toJson() => {'zone': zone, 'type': type};

  factory HandoverDamagePin.fromJson(Map<String, dynamic> json) =>
      HandoverDamagePin(
        zone: json['zone'] as String? ?? '',
        type: json['type'] as String? ?? '',
      );

  @override
  List<Object?> get props => [zone, type];
}

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
  final String? customerId;
  final String? customerName;
  final String? cnicNumber;
  final String? vehicleDetails;
  final int? totalAmount;

  /// Audit 2026-11-15 PW-16: the balance due at handover (total −
  /// advance paid) and how it was collected ('cash' | 'jazzcash' |
  /// 'easypaisa' | 'bank_transfer' | 'not_yet'). First-class fields
  /// on the handover record — the view used to merge them onto the
  /// agreement doc best-effort, bypassing the offline queue, so an
  /// offline handover lost the balance record entirely.
  final int? balanceDuePkr;
  final String? balancePaymentMethod;

  /// Financial audit (2026-11-20): whether the balance was
  /// actually received at handover. Before this the record carried
  /// the amount + a method but no received flag — a balance picked
  /// as 'cash' with the Received toggle OFF looked exactly like a
  /// collected one, and the booking's remaining balance was never
  /// reduced either way. Null on older records (unknown).
  final bool? balanceReceived;

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

  /// Item 9 (O26–O30): the 5-step handover wizard's new fields.
  /// All nullable / defaulted so records saved before the wizard
  /// keep round-tripping unchanged.
  ///
  /// O26: the manual face check — the owner confirms the customer
  /// against the KYC profile photo. NO match percentage is ever
  /// stored: the spec's "94%" is a mockup number, and no face-match
  /// SDK exists in the app. Only a confirmed flag + timestamp.
  final bool faceCheckConfirmed;
  final DateTime? faceCheckedAt;

  /// O27: the deposit's own collection method + when it was
  /// actually received (the Received toggle), and the in-app
  /// receipt id (`RH-RCT-<bookingId>`).
  final String? depositPaymentMethod;
  final DateTime? depositReceivedAt;
  final String? receiptId;

  /// O28: the condition checkboxes on the checklist step.
  final bool? acWorking;
  final bool? lightsWorking;

  /// O29: the two extra photo slots (interior, dashboard) plus a
  /// per-photo taken-at timestamp (side → ISO-8601), and the
  /// damage pins tapped on the car diagram.
  final String? photoInteriorUrl;
  final String? photoDashboardUrl;
  final Map<String, String> photoTakenAt;
  final List<HandoverDamagePin> damagePins;

  /// O30: when the trip started (certify time — the trip timer on
  /// Rental Started counts from here), when the wizard itself
  /// completed, and where each signature came from ('saved' = the
  /// KYC / shop on-file signature, 'fresh' = drawn on the pad).
  final DateTime? tripStartAt;
  final DateTime? wizardCompletedAt;
  final String? customerSignatureSource;
  final String? ownerSignatureSource;

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
    this.customerId,
    this.customerName,
    this.cnicNumber,
    this.vehicleDetails,
    this.totalAmount,
    this.balanceDuePkr,
    this.balancePaymentMethod,
    this.balanceReceived,
    this.photoFrontUrl,
    this.photoBackUrl,
    this.photoLeftUrl,
    this.photoRightUrl,
    this.documentsGiven = const [],
    this.accessories = const [],
    this.keysHandedOver = false,
    this.faceCheckConfirmed = false,
    this.faceCheckedAt,
    this.depositPaymentMethod,
    this.depositReceivedAt,
    this.receiptId,
    this.acWorking,
    this.lightsWorking,
    this.photoInteriorUrl,
    this.photoDashboardUrl,
    this.photoTakenAt = const {},
    this.damagePins = const [],
    this.tripStartAt,
    this.wizardCompletedAt,
    this.customerSignatureSource,
    this.ownerSignatureSource,
  });

  HandoverEntity copyWith({
    String? agreementPdfUrl,
    bool? isSynced,
    String? agreementPdfB64,
    int? balanceDuePkr,
    String? balancePaymentMethod,
    bool? balanceReceived,
    String? photoFrontUrl,
    String? photoBackUrl,
    String? photoLeftUrl,
    String? photoRightUrl,
    List<String>? documentsGiven,
    List<String>? accessories,
    bool? keysHandedOver,
    bool? faceCheckConfirmed,
    DateTime? faceCheckedAt,
    String? depositPaymentMethod,
    DateTime? depositReceivedAt,
    String? receiptId,
    bool? acWorking,
    bool? lightsWorking,
    String? photoInteriorUrl,
    String? photoDashboardUrl,
    Map<String, String>? photoTakenAt,
    List<HandoverDamagePin>? damagePins,
    DateTime? tripStartAt,
    DateTime? wizardCompletedAt,
    String? customerSignatureSource,
    String? ownerSignatureSource,
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
      balanceDuePkr: balanceDuePkr ?? this.balanceDuePkr,
      balancePaymentMethod:
          balancePaymentMethod ?? this.balancePaymentMethod,
      balanceReceived: balanceReceived ?? this.balanceReceived,
      shopId: shopId,
      shopName: shopName,
      customerId: customerId,
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
      faceCheckConfirmed: faceCheckConfirmed ?? this.faceCheckConfirmed,
      faceCheckedAt: faceCheckedAt ?? this.faceCheckedAt,
      depositPaymentMethod:
          depositPaymentMethod ?? this.depositPaymentMethod,
      depositReceivedAt: depositReceivedAt ?? this.depositReceivedAt,
      receiptId: receiptId ?? this.receiptId,
      acWorking: acWorking ?? this.acWorking,
      lightsWorking: lightsWorking ?? this.lightsWorking,
      photoInteriorUrl: photoInteriorUrl ?? this.photoInteriorUrl,
      photoDashboardUrl: photoDashboardUrl ?? this.photoDashboardUrl,
      photoTakenAt: photoTakenAt ?? this.photoTakenAt,
      damagePins: damagePins ?? this.damagePins,
      tripStartAt: tripStartAt ?? this.tripStartAt,
      wizardCompletedAt: wizardCompletedAt ?? this.wizardCompletedAt,
      customerSignatureSource:
          customerSignatureSource ?? this.customerSignatureSource,
      ownerSignatureSource:
          ownerSignatureSource ?? this.ownerSignatureSource,
    );
  }

  /// Item 10 (O46–O48): the true count of exterior photos actually
  /// taken at handover (4 slots today) — never the spec's "8".
  /// Item 9 (O29): the wizard adds Interior + Dashboard, so the
  /// count now covers all six slots.
  int get photoCount => [
        photoFrontUrl,
        photoBackUrl,
        photoLeftUrl,
        photoRightUrl,
        photoInteriorUrl,
        photoDashboardUrl,
      ].where((url) => url != null && url.isNotEmpty).length;

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
        customerId,
        customerName,
        cnicNumber,
        vehicleDetails,
        totalAmount,
        balanceDuePkr,
        balancePaymentMethod,
        balanceReceived,
        photoFrontUrl,
        photoBackUrl,
        photoLeftUrl,
        photoRightUrl,
        documentsGiven,
        accessories,
        keysHandedOver,
        faceCheckConfirmed,
        faceCheckedAt,
        depositPaymentMethod,
        depositReceivedAt,
        receiptId,
        acWorking,
        lightsWorking,
        photoInteriorUrl,
        photoDashboardUrl,
        photoTakenAt,
        damagePins,
        tripStartAt,
        wizardCompletedAt,
        customerSignatureSource,
        ownerSignatureSource,
      ];
}
