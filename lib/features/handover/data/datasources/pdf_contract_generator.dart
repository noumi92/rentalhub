import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/constants/api_endpoints.dart';

/// Phase B (E3): a real A4 rental agreement, built with the `pdf`
/// package — parties, vehicle, rental terms, handover telemetry,
/// the two drawn signatures as images, and a QR code that opens the
/// verification page. The previous generator only wrote a text blob
/// with a "%PDF-1.4" header; no PDF reader could open it.
class PdfContractGenerator {
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

    pw.Widget signatureBox(String label, Uint8List? png) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Container(
            width: 200,
            height: 70,
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400)),
            child: png != null
                ? pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain)
                : pw.Center(
                    child: pw.Text('Not signed',
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600))),
          ),
        ],
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
                      child: pw.Text('CERTIFIED DIGITAL RENTAL CONTRACT',
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
              pw.Text('Rented Vehicle', style: heading),
              row('Vehicle:', vehicleDetails),
              row('Package:', '$packageType '
                  '(${isWithDriver ? "With Chauffeur" : "Self-Drive"})'),
              row('Pickup:', _dateTime(pickupTime)),
              row('Return:', _dateTime(returnTime)),
              row('Total rent:', 'Rs. $totalAmount'),
              row('Advance paid:', 'Rs. $advancePaid'),
              row('Security deposit:', 'Rs. $securityDeposit (refundable)'),
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
                '1. The vehicle shall not be driven across unauthorized '
                'provincial checkpoints without an NOC.\n'
                '2. Traffic challans, e-tickets and fuel consumed are the '
                'sole liability of the hirer.\n'
                '3. Any default will result in an FIR and a National '
                'Tribunal Blacklist listing.\n'
                '4. The security deposit is refunded after inspection at '
                'return, less any damage or extra-kilometre charges.',
                style: pw.TextStyle(fontSize: 10, height: 1.4),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  signatureBox('Hirer Signature', customerSignaturePng),
                  signatureBox('Host Seal & Signature', ownerSignaturePng),
                ],
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
