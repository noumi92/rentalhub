import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Audit impl finish: the signature block used by the A4 agreement PDF
/// (extracted from [PdfContractGenerator] so that file stays under the
/// 250-line cap). A null image renders an honest "Not signed" box —
/// never an invented signature. Behaviour is identical to the inline
/// closure it replaces.
pw.Widget pdfSignatureBox(String label, Uint8List? png, String dateLine) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label,
          style:
              pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Container(
        width: 160,
        height: 70,
        decoration:
            pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
        child: png != null
            ? pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain)
            : pw.Center(
                child: pw.Text('Not signed',
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600))),
      ),
      pw.SizedBox(height: 4),
      pw.Text(dateLine,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
    ],
  );
}
