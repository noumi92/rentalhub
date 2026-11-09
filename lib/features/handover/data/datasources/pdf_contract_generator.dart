import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/money_format.dart';
import 'pdf_signature_box.dart';

/// Phase B (E3): a real A4 rental agreement, built with the `pdf`
/// package — parties, vehicle, rental terms, handover telemetry,
/// the three drawn signatures as images, and a QR code that opens the
/// verification page. The previous generator only wrote a text blob
/// with a "%PDF-1.4" header; no PDF reader could open it.
class PdfContractGenerator {
  /// Audit impl (finish): the title printed on the agreement PDF.
  static const String agreementTitle = 'RENTAL AGREEMENT';

  /// Audit impl (finish): the 10 spec terms printed on the PDF.
  /// Terms 1, 2 and 4–10 are IDENTICAL to the `.arb`
  /// contractTerm1/2/4–10 values. Term 3 is reproduced EXACTLY as
  /// before — its legal wording ("FIR and a National Tribunal
  /// Blacklist listing") awaits the user's own call; do not touch it.
  static const List<String> agreementTerms = [
    '1. The vehicle shall be used within city limits unless an out-city rate has been agreed.',
    '2. Traffic challans, e-tickets and fuel consumed are sole liability of the hirer.',
    '3. Any default will result in an FIR and a National Tribunal Blacklist listing.',
    '4. Fuel shall be returned at the same level as at handover.',
    '5. Late return is charged per hour or per day as per the agreed package.',
    '6. Damage is charged as per inspection at return.',
    '7. The owner is not liable for personal belongings left in the vehicle.',
    '8. This agreement is governed by the laws of Pakistan.',
    '9. The security deposit is refunded after inspection at return, less any damage or extra-kilometre charges.',
    '10. Both parties agree to the terms above.',
  ];

  /// The page that proves an agreement is genuine. The id is the
  /// booking id; the PHP page reads the matching `agreements` doc
  /// from Firestore (see `verify_agreement.php`, D6).
  static String verificationUrlFor(String agreementId) {
    return '${ApiEndpoints.cpanelBaseUrl}/api/verify_agreement.php'
        '?id=${Uri.encodeComponent(agreementId)}';
  }

  static Future<Uint8List> generateA4Agreement({
    required String agreementId,
    required String shopName,
    required String customerName,
    required String cnicNumber,
    required String customerPhone,
    required String vehicleDetails,
    required String packageType,
    required bool isWithDriver,
    required DateTime pickupTime,
    required DateTime returnTime,
    required int totalAmount,
    required int advancePaid,
    required int securityDeposit,
    required int initialOdometer,
    required String fuelLevel,
    required List<String> damageNotes,
    Uint8List? customerSignaturePng,
    Uint8List? ownerSignaturePng,
    // Finish build (O20): the guarantor / witness signature, captured
    // on the contract view — null renders an honest "Not signed" box,
    // never an invented signature.
    Uint8List? guarantorSignaturePng,
    String? guarantorName,
    // Audit item 14 (O23): real vehicle detail + host name for the
    // parties / vehicle sections. Null renders as "—", never invented.
    String? vehiclePlate,
    String? vehicleColour,
    String? vehicleFuel,
    String? ownerName,
  }) async {
    final doc = pw.Document();
    final verifyUrl = verificationUrlFor(agreementId);
    final style = pw.TextStyle(fontSize: 11, color: PdfColors.black);
    final heading = pw.TextStyle(
        fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black);

    pw.Widget row(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: style),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(shopName.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('Govt. Registered Commercial Motor Car Rental Agency',
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      color: PdfColors.blue900,
                      child: pw.Text(agreementTitle,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 1.5),
              row('Agreement No:', '#$agreementId'),
              row('Date:', _date(pickupTime)),
              pw.SizedBox(height: 8),
              pw.Text('Hirer / Customer', style: heading),
              row('Name:', customerName),
              row('CNIC:', cnicNumber),
              row('Phone:', customerPhone),
              pw.SizedBox(height: 8),
              pw.Text('Owner / Host', style: heading),
              row('Name:', ownerName ?? shopName),
              row('Shop:', shopName),
              pw.SizedBox(height: 8),
              pw.Text('Rented Vehicle', style: heading),
              row('Vehicle:', vehicleDetails),
              if (vehiclePlate != null && vehiclePlate.isNotEmpty)
                row('Plate:', vehiclePlate),
              if (vehicleColour != null && vehicleColour.isNotEmpty)
                row('Colour:', vehicleColour),
              if (vehicleFuel != null && vehicleFuel.isNotEmpty)
                row('Fuel:', vehicleFuel),
              row('Package:', '$packageType '
                  '(${isWithDriver ? "With Chauffeur" : "Self-Drive"})'),
              row('Pickup:', _dateTime(pickupTime)),
              row('Return:', _dateTime(returnTime)),
              row('Total rent:', 'Rs. ${formatRs(totalAmount)}'),
              row('Advance paid:', 'Rs. ${formatRs(advancePaid)}'),
              row('Remaining:', 'Rs. ${formatRs(totalAmount - advancePaid)}'),
              row('Security deposit:',
                  'Rs. ${formatRs(securityDeposit)} (refundable)'),
              pw.SizedBox(height: 8),
              pw.Text('Handover Inspection', style: heading),
              row('Departure odometer:', '$initialOdometer KM'),
              row('Fuel gauge:', fuelLevel),
              row('Damage noted:',
                  damageNotes.isEmpty ? 'None' : damageNotes.join('; ')),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Terms & Conditions (Pakistan Jurisdiction)', style: heading),
              pw.Text(
                agreementTerms.join('\n'),
                style: pw.TextStyle(fontSize: 10, height: 1.4),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pdfSignatureBox('Hirer Signature', customerSignaturePng,
                      'Date: ${_date(pickupTime)}'),
                  pdfSignatureBox('Host Seal & Signature', ownerSignaturePng,
                      'Date: ${_date(pickupTime)}'),
                  // Finish build (O20): the third signature block.
                  pdfSignatureBox(
                      'Guarantor Signature', guarantorSignaturePng,
                      guarantorName != null && guarantorName.isNotEmpty
                          ? guarantorName
                          : 'Date: ${_date(pickupTime)}'),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                width: 200, height: 70,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Center(child: pw.Text('Shop Stamp', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600))),
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: verifyUrl,
                    width: 80,
                    height: 80,
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Text(
                      'Verify this agreement:\n$verifyUrl',
                      style: pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey700),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  static String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  static String _dateTime(DateTime d) {
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${_date(d)} $hour:$minute';
  }
}
