import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';

/// RQ-F17 (2026-11-13): extracted from `OwnerAddVehicleView` so the
/// view stays under the 250-line cap (rulebook §2.2 / D19).
///
/// "Label: filename" for every picked photo/document, shown on the
/// review step — the back/side/interior photos, reg book, token tax
/// and insurance. Only picked files are listed, never invented names.
List<String> pickedVehicleDocNames(
  AppLocalizations l10n, {
  required XFile? photoBackFile,
  required XFile? photoSideFile,
  required XFile? photoInteriorFile,
  required XFile? regBookFile,
  required XFile? tokenTaxFile,
  required XFile? insuranceFile,
}) {
  final names = <String>[];
  void add(String label, XFile? f) {
    if (f != null) names.add('$label: ${f.name}');
  }

  add(l10n.addVehiclePhotoRear, photoBackFile);
  add(l10n.addVehiclePhotoSide, photoSideFile);
  add(l10n.addVehiclePhotoInterior, photoInteriorFile);
  add(l10n.addVehicleDocRegBook, regBookFile);
  add(l10n.addVehicleDocTokenTax, tokenTaxFile);
  add(l10n.addVehicleDocInsurance, insuranceFile);
  return names;
}
