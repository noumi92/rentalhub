# DOC-10: Phase 3 Detailed Implementation Plan
## Offline Handover, Digital Legal Contract & Communications
### Project: RentalHub (`rentalhub`)

---

## 1. Phase Objective & Definition of Done (DoD)

### 1.1 Objective
Implement the paperless vehicle handover system featuring **offline-first local persistence** (Hive boxes & sync queue), digital inspection checklist (fuel, odometer, 4-quadrant damage markers), on-screen dual touch signature capture, automated on-device generation of printable **A4 PDF rental agreements**, upload to cPanel secure storage, and server-side **Meta WhatsApp Cloud API** transactional notifications via Firebase Cloud Functions.

### 1.2 Definition of Done (DoD)
- [ ] Vehicle handover flow functions 100% offline in basement parking lots with zero data loss using Hive caching.
- [ ] On-screen touch signature canvas captures smooth vector strokes for both Customer and Owner matching Stitch ANC-14 [14_vehicle_handover_signature.html](file:///e:/Commercial/Gari%20App/.stitch/14_vehicle_handover_signature.html).
- [ ] On-device `pdf` generator compiles an authentic printable A4 rental agreement containing logos, booking specs, KYC details, inspection checklists, damage photos, and vector signatures.
- [ ] The generated PDF and inspection photos upload to cPanel secure storage (`/storage/upload.php`, `category: agreements`), returning tokenized HTTPS URLs.
- [ ] Background `SyncEngine` auto-syncs queued inspection data and uploads photos once network connectivity is restored.
- [ ] Firebase Cloud Functions (Node.js) trigger on booking changes to dispatch transactional WhatsApp templates via Meta Cloud API with the downloadable agreement PDF link.
- [ ] Return inspection calculates extra mileage and fuel deficit penalties, settling final balances and capturing mutual reviews matching Stitch ANC-15 [15_owner_return_settlement.html](file:///e:/Commercial/Gari%20App/.stitch/15_owner_return_settlement.html) and ANC-08 [08_rate_trip_feedback.html](file:///e:/Commercial/Gari%20App/.stitch/08_rate_trip_feedback.html).
- [ ] Fraud incident reporting desk allows owners to attach police FIR and report severe violations directly matching Stitch ANC-16 [16_owner_fraud_blacklist.html](file:///e:/Commercial/Gari%20App/.stitch/16_owner_fraud_blacklist.html).

---

## 2. Infrastructure & UI Design Anchor Bindings

1. **Storage Endpoints**: cPanel REST storage deployed in Phase 0 (`public_html/storage/upload.php`) under category `agreements`.
2. **Serverless Cloud Triggers**: Firebase Cloud Functions deployed to `rentalhub-production` listening to `bookings/{id}` write events.
3. **Meta WhatsApp Cloud API**: System User Token stored securely in Firebase Environment Secrets (`META_ACCESS_TOKEN`, `META_PHONE_NUMBER_ID`).
4. **Stitch UI Anchors in `.stitch/`**:
   - Handover & Signatures: ANC-14 ([14_vehicle_handover_signature.html](file:///e:/Commercial/Gari%20App/.stitch/14_vehicle_handover_signature.html))
   - Return & Settlement: ANC-15 ([15_owner_return_settlement.html](file:///e:/Commercial/Gari%20App/.stitch/15_owner_return_settlement.html))
   - Fraud Blacklist Desk: ANC-16 ([16_owner_fraud_blacklist.html](file:///e:/Commercial/Gari%20App/.stitch/16_owner_fraud_blacklist.html))
   - Renter Feedback: ANC-08 ([08_rate_trip_feedback.html](file:///e:/Commercial/Gari%20App/.stitch/08_rate_trip_feedback.html))

---

## 3. Directory Structure for Phase 3

```
lib/features/
├── handover/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── handover_remote_data_source.dart
│   │   │   └── handover_local_data_source.dart
│   │   ├── models/
│   │   │   ├── handover_inspection_model.dart
│   │   │   └── offline_sync_item.dart
│   │   └── repositories/handover_repository_impl.dart
│   ├── domain/
│   │   ├── entities/handover_entity.dart
│   │   └── usecases/
│   │       ├── complete_handover_usecase.dart
│   │       └── sync_offline_handovers_usecase.dart
│   └── presentation/
│       ├── cubit/handover_cubit.dart
│       └── views/
│           ├── vehicle_handover_view.dart
│           ├── return_settlement_view.dart
│           └── widgets/
│               ├── signature_canvas_pad.dart
│               ├── damage_quadrant_canvas.dart
│               ├── fuel_gauge_selector.dart
│               └── pdf_agreement_preview_dialog.dart
└── trust/
    └── presentation/views/
        ├── rate_customer_sheet.dart
        └── rate_trip_view.dart

backend/
└── functions/
    ├── src/
    │   ├── index.ts
    │   ├── triggers/on_booking_updated.ts
    │   └── services/meta_whatsapp_service.ts
    ├── package.json
    └── tsconfig.json
```

---

## 4. Detailed Step-by-Step Task Breakdown

### Task 3.1: Offline Hive Storage & Sync Queue
Configure local Hive TypeAdapters in `lib/features/handover/data/datasources/handover_local_data_source.dart`:

```dart
import 'package:hive/hive.dart';

class HandoverLocalDataSource {
  static const String handoverBoxName = 'offline_handovers';
  static const String syncQueueBoxName = 'sync_queue';

  Future<void> saveHandoverOffline({
    required String bookingId,
    required int odometer,
    required String fuelLevel,
    required List<String> localPhotoPaths,
    required String customerSignatureSvg,
    required String ownerSignatureSvg,
  }) async {
    final box = await Hive.openBox(handoverBoxName);
    await box.put(bookingId, {
      'booking_id': bookingId,
      'odometer': odometer,
      'fuel_level': fuelLevel,
      'photo_paths': localPhotoPaths,
      'customer_signature': customerSignatureSvg,
      'owner_signature': ownerSignatureSvg,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': false,
    });

    // Enqueue in sync queue
    final queueBox = await Hive.openBox(syncQueueBoxName);
    await queueBox.add({
      'type': 'SYNC_HANDOVER',
      'booking_id': bookingId,
      'enqueued_at': DateTime.now().toIso8601String(),
    });
  }
}
```

---

### Task 3.2: Dual Touch Signature Canvas Pad
Implement vector signature capture in `lib/features/handover/presentation/views/widgets/signature_canvas_pad.dart`:

```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignatureCanvasPad extends StatefulWidget {
  final String title;
  final Function(List<Offset?> points) onSignatureChanged;

  const SignatureCanvasPad({
    super.key,
    required this.title,
    required this.onSignatureChanged,
  });

  @override
  State<SignatureCanvasPad> createState() => _SignatureCanvasPadState();
}

class _SignatureCanvasPadState extends State<SignatureCanvasPad> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () => setState(() {
                _points.clear();
                widget.onSignatureChanged(_points);
              }),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                _points.add(renderBox.globalToLocal(details.globalPosition));
              });
              widget.onSignatureChanged(_points);
            },
            onPanEnd: (_) => _points.add(null),
            child: CustomPaint(
              painter: _SignaturePainter(points: _points),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color(0xFF1B1E5C)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

---

### Task 3.3: Printable A4 PDF Rental Agreement Generator
Generate legally structured A4 PDF in `lib/features/handover/data/datasources/pdf_contract_generator.dart`:

```dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfContractGenerator {
  static Future<Uint8List> generateA4Agreement({
    required String agreementId,
    required String shopName,
    required String customerName,
    required String cnicNumber,
    required String vehicleDetails,
    required int initialOdometer,
    required String fuelLevel,
    required Uint8List customerSignatureBytes,
    required Uint8List ownerSignatureBytes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('RENTALHUB DIGITAL AGREEMENT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                  pw.Text('Ref: #$agreementId', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.teal800),
              pw.SizedBox(height: 12),

              // Parties
              pw.Text('1. PARTIES & VEHICLE DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Rental Shop: $shopName'),
              pw.Text('Customer: $customerName (CNIC: $cnicNumber)'),
              pw.Text('Vehicle: $vehicleDetails'),
              pw.SizedBox(height: 12),

              // Inspection
              pw.Text('2. HANDOVER CONDITION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Initial Mileage: $initialOdometer KM | Fuel Level: $fuelLevel'),
              pw.SizedBox(height: 16),

              // Legal Terms
              pw.Text('3. TERMS & CONDITIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('The renter agrees to operate the vehicle responsibly and return on agreed schedule. Any damage or traffic violations are the sole responsibility of the renter.', style: const pw.TextStyle(fontSize: 9)),
              pw.Spacer(),

              // Dual Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Image(pw.MemoryImage(customerSignatureBytes), width: 140, height: 60),
                      pw.Container(width: 160, height: 1, color: PdfColors.black),
                      pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Image(pw.MemoryImage(ownerSignatureBytes), width: 140, height: 60),
                      pw.Container(width: 160, height: 1, color: PdfColors.black),
                      pw.Text('Authorized Shop Signature', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
```

---

### Task 3.4: Meta WhatsApp Cloud API via Firebase Cloud Functions
Implement Cloud Function in `backend/functions/src/triggers/on_booking_updated.ts`:

```typescript
import * as functions from 'firebase-functions';
import axios from 'axios';

const META_ACCESS_TOKEN = process.env.META_PERMANENT_ACCESS_TOKEN;
const META_PHONE_NUMBER_ID = process.env.META_PHONE_NUMBER_ID;

export const onBookingUpdated = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Trigger on Handover completion (status shifts to 'on_trip')
    if (before.status !== 'on_trip' && after.status === 'on_trip') {
      const customerPhone = after.customer_phone; // e.g. '923001234567'
      const agreementPdfUrl = after.agreement_pdf_url;
      const vehicleName = after.vehicle_name;

      // Call Meta Graph API
      await axios.post(
        `https://graph.facebook.com/v20.0/${META_PHONE_NUMBER_ID}/messages`,
        {
          messaging_product: 'whatsapp',
          to: customerPhone,
          type: 'template',
          template: {
            name: 'rental_agreement_pdf_dispatch',
            language: { code: 'en_US' },
            components: [
              {
                type: 'body',
                parameters: [
                  { type: 'text', text: after.customer_name },
                  { type: 'text', text: vehicleName },
                  { type: 'text', text: agreementPdfUrl }
                ]
              }
            ]
          }
        },
        {
          headers: {
            Authorization: `Bearer ${META_ACCESS_TOKEN}`,
            'Content-Type': 'application/json'
          }
        }
      );
    }
  });
```

---

## 5. Phase 3 Testing & Reliability Checklist

- [ ] Disable device network (Airplane mode) ➔ Execute handover ➔ Verify data written to local Hive box without crash.
- [ ] Restore network ➔ Verify `SyncEngine` uploads photos, creates Firestore agreement doc, and cleans queue.
- [ ] Compiled A4 PDF renders signatures cleanly and displays all inspection fields.
- [ ] Cloud Function executes and returns HTTP 200 from Meta WhatsApp Graph API.

---

## 6. Document Revision History
| Version | Date | Author / Agent | Change Type | Summary of Changes |
| :--- | :--- | :--- | :--- | :--- |
| **1.0.0** | 2026-10-31 | Lead Architect (Antigravity) | Initial Creation | Complete Phase 3 Detailed Implementation Plan for RentalHub. |
| **1.1.0** | 2026-11-01 | Lead Architect (Antigravity) | Type C & Type J | Linked cPanel storage category (agreements), Firebase Cloud Functions deployment, Meta WhatsApp Cloud API credentials, and mapped Stitch anchor screens ANC-08, ANC-14, ANC-15, and ANC-16. |
