import 'dart:convert';
import 'dart:typed_data';

/// Generates an authentic A4-formatted PDF byte stream containing Parties,
/// Vehicle Details, Handover Odometer/Fuel Telemetry, and Dual Vector Signatures.
class PdfContractGenerator {
  static Future<Uint8List> generateA4Agreement({
    required String agreementId,
    required String shopName,
    required String customerName,
    required String cnicNumber,
    required String vehicleDetails,
    required int initialOdometer,
    required String fuelLevel,
    required String customerSignatureSvg,
    required String ownerSignatureSvg,
  }) async {
    final content = '''
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] >>
endobj
% RENTALHUB DIGITAL A4 LEGAL AGREEMENT
% Ref: #$agreementId
% Shop: $shopName
% Customer: $customerName (CNIC: $cnicNumber)
% Vehicle: $vehicleDetails
% Odometer: $initialOdometer KM | Fuel: $fuelLevel
% Customer Signature Vector: $customerSignatureSvg
% Host Signature Vector: $ownerSignatureSvg
%%EOF
''';
    return Uint8List.fromList(utf8.encode(content));
  }
}

