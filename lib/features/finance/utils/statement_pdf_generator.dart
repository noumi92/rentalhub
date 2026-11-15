import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../bookings/domain/entities/booking_entity.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';

/// Audit impl (O47): a real A4 customer statement, built with the
/// `pdf` package following [PdfContractGenerator]'s pattern — shop
/// header, customer, one row per booking (booking / date / rent /
/// paid / due) and the total due. The PDF itself carries no
/// localised strings (the `pdf` package has no l10n); the labels
/// are the English statement wording, as in the agreement PDF.
class StatementPdfGenerator {
  static Future<Uint8List> generateCustomerStatement({
    required String shopName,
    required String customerName,
    required String customerPhone,
    required List<BookingEntity> bookings,
  }) async {
    final doc = pw.Document();
    final totalDue =
        bookings.fold<int>(0, (total, b) => total + b.remainingBalance);
    final totalRent =
        bookings.fold<int>(0, (total, b) => total + b.totalAmount);
    final totalPaid =
        bookings.fold<int>(0, (total, b) => total + b.advancePaid);
    final style = pw.TextStyle(fontSize: 11, color: PdfColors.black);
    final heading = pw.TextStyle(
        fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black);
    final headerStyle = pw.TextStyle(
        fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white);

    pw.Widget cell(String text, {bool bold = false, bool right = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(text,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
    }

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
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      color: PdfColors.blue900,
                      child: pw.Text('CUSTOMER STATEMENT',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 1.5),
              pw.Text('Customer', style: heading),
              row('Name:', customerName),
              if (customerPhone.isNotEmpty) row('Phone:', customerPhone),
              row('Date:', _date(DateTime.now())),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blue900),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Booking', style: headerStyle)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Date', style: headerStyle)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Rent', style: headerStyle)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Paid', style: headerStyle)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Due', style: headerStyle)),
                    ],
                  ),
                  for (final b in bookings)
                    pw.TableRow(children: [
                      cell('#${b.bookingId}'),
                      cell(_date(b.pickupTime)),
                      cell('Rs. ${formatRs(b.totalAmount)}', right: true),
                      cell('Rs. ${formatRs(b.advancePaid)}', right: true),
                      cell('Rs. ${formatRs(b.remainingBalance)}', right: true),
                    ]),
                  pw.TableRow(children: [
                    cell('Total', bold: true),
                    cell(''),
                    cell('Rs. ${formatRs(totalRent)}', bold: true, right: true),
                    cell('Rs. ${formatRs(totalPaid)}', bold: true, right: true),
                    cell('Rs. ${formatRs(totalDue)}', bold: true, right: true),
                  ]),
                ],
              ),
              pw.SizedBox(height: 16),
              row('Total due:', 'Rs. ${formatRs(totalDue)}'),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  // Audit 2026-11-15 DS-5: unambiguous "5 Nov 2026", never raw d/m/y.
  // No BuildContext in a PDF generator, so the English locale is pinned
  // (the statement is generated in English). formatDateEn is intl-free:
  // DateFormat.yMMMd('en') throws LocaleDataException in plain tests.
  static String _date(DateTime d) => formatDateEn(d);
}
