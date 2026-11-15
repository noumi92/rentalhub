import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../bookings/domain/entities/booking_entity.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';

/// Audit impl (O37): a real A4 earnings report, built with the
/// `pdf` package following [StatementPdfGenerator]'s pattern —
/// shop header, period, monthly earnings (last 6 months, same
/// statuses and window as the on-screen bar chart) and the
/// car-wise table (same period-filtered rows as the on-screen
/// table). The PDF itself carries no localised strings (the `pdf`
/// package has no l10n); the labels are the English report
/// wording, as in the agreement and statement PDFs. CSV export
/// stays untouched — the `excel` package is never reintroduced.
class ReportPdfGenerator {
  /// Monthly earnings for the last 6 months: (month label, booking
  /// count, earnings). Only paid / active / completed trips count,
  /// exactly like [ReportEarningsChart].
  static List<(String, int, int)> monthlyRows(
      List<BookingEntity> bookings) {
    final now = DateTime.now();
    final rows = <(String, int, int)>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthBookings = bookings.where((b) =>
          (b.status == 'completed' ||
              b.status == 'paid' ||
              b.status == 'active') &&
          b.pickupTime.year == month.year &&
          b.pickupTime.month == month.month);
      rows.add((
        DateFormat('MMM yyyy').format(month),
        monthBookings.length,
        monthBookings.fold<int>(0, (total, b) => total + b.totalAmount),
      ));
    }
    return rows;
  }

  static Future<Uint8List> generateReportPdf({
    required String shopName,
    required String periodLabel,
    required List<(String, int, int)> monthlyRows,
    required List<(String, int, int)> carRows,
  }) async {
    final doc = pw.Document();
    final totalMonthly =
        monthlyRows.fold<int>(0, (total, r) => total + r.$3);
    final totalCar = carRows.fold<int>(0, (total, r) => total + r.$3);
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

    pw.Widget table({
      required List<String> headers,
      required List<List<String>> rows,
      required List<String> totals,
    }) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1),
          2: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue900),
            children: [
              for (final h in headers)
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h, style: headerStyle)),
            ],
          ),
          for (final r in rows)
            pw.TableRow(children: [
              cell(r[0]),
              cell(r[1], right: true),
              cell(r[2], right: true),
            ]),
          pw.TableRow(children: [
            cell(totals[0], bold: true),
            cell(totals[1], bold: true, right: true),
            cell(totals[2], bold: true, right: true),
          ]),
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
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      color: PdfColors.blue900,
                      child: pw.Text('EARNINGS REPORT',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 1.5),
              row('Period:', periodLabel),
              row('Date:', _date(DateTime.now())),
              pw.SizedBox(height: 12),
              pw.Text('Monthly Earnings — last 6 months', style: heading),
              pw.SizedBox(height: 6),
              table(
                headers: const ['Month', 'Bookings', 'Earnings'],
                rows: [
                  for (final r in monthlyRows)
                    [r.$1, '${r.$2}', 'Rs. ${formatRs(r.$3)}'],
                ],
                totals: [
                  'Total',
                  '${monthlyRows.fold<int>(0, (t, r) => t + r.$2)}',
                  'Rs. ${formatRs(totalMonthly)}',
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Car-wise Earnings — $periodLabel', style: heading),
              pw.SizedBox(height: 6),
              if (carRows.isEmpty)
                pw.Text('No cars in the fleet yet.', style: style)
              else
                table(
                  headers: const ['Car', 'Bookings', 'Earnings'],
                  rows: [
                    for (final r in carRows)
                      [r.$1, '${r.$2}', 'Rs. ${formatRs(r.$3)}'],
                  ],
                  totals: [
                    'Total',
                    '${carRows.fold<int>(0, (t, r) => t + r.$2)}',
                    'Rs. ${formatRs(totalCar)}',
                  ],
                ),
              pw.SizedBox(height: 16),
              row('Total earnings ($periodLabel):',
                  'Rs. ${formatRs(totalCar)}'),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  // Audit 2026-11-15 DS-5: unambiguous "5 Nov 2026", never raw d/m/y.
  // No BuildContext in a PDF generator, so the English locale is pinned
  // (the report is generated in English). formatDateEn is intl-free:
  // DateFormat.yMMMd('en') throws LocaleDataException in plain tests.
  static String _date(DateTime d) => formatDateEn(d);
}
