import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../onboarding/onboarding_document_tile.dart';
import '../onboarding/onboarding_photo_upload_box.dart';

class VehiclePhotosStepWidget extends StatelessWidget {
  final XFile? photoFrontFile;
  final VoidCallback onPickFront;
  final VoidCallback onRemoveFront;

  final XFile? photoBackFile;
  final VoidCallback onPickBack;
  final VoidCallback onRemoveBack;

  final XFile? photoSideFile;
  final VoidCallback onPickSide;
  final VoidCallback onRemoveSide;

  final XFile? photoInteriorFile;
  final VoidCallback onPickInterior;
  final VoidCallback onRemoveInterior;

  final XFile? regBookFile;
  final VoidCallback onPickRegBook;
  final VoidCallback onRemoveRegBook;

  final XFile? tokenTaxFile;
  final VoidCallback onPickTokenTax;
  final VoidCallback onRemoveTokenTax;

  final XFile? insuranceFile;
  final VoidCallback onPickInsurance;
  final VoidCallback onRemoveInsurance;

  const VehiclePhotosStepWidget({
    super.key,
    required this.photoFrontFile,
    required this.onPickFront,
    required this.onRemoveFront,
    required this.photoBackFile,
    required this.onPickBack,
    required this.onRemoveBack,
    required this.photoSideFile,
    required this.onPickSide,
    required this.onRemoveSide,
    required this.photoInteriorFile,
    required this.onPickInterior,
    required this.onRemoveInterior,
    required this.regBookFile,
    required this.onPickRegBook,
    required this.onRemoveRegBook,
    required this.tokenTaxFile,
    required this.onPickTokenTax,
    required this.onRemoveTokenTax,
    required this.insuranceFile,
    required this.onPickInsurance,
    required this.onRemoveInsurance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addVehiclePhotosTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.addVehiclePhotosHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),

        // 4 Car Photos Grid (Camera + Gallery + Remove)
        Row(
          children: [
            Expanded(
              child: OnboardingPhotoUploadBox(
                label: l10n.addVehiclePhotoFront,
                file: photoFrontFile,
                onTap: onPickFront,
                onRemove: photoFrontFile != null ? onRemoveFront : null,
                height: 110,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OnboardingPhotoUploadBox(
                label: l10n.addVehiclePhotoRear,
                file: photoBackFile,
                onTap: onPickBack,
                onRemove: photoBackFile != null ? onRemoveBack : null,
                height: 110,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OnboardingPhotoUploadBox(
                label: l10n.addVehiclePhotoSide,
                file: photoSideFile,
                onTap: onPickSide,
                onRemove: photoSideFile != null ? onRemoveSide : null,
                height: 110,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OnboardingPhotoUploadBox(
                label: l10n.addVehiclePhotoInterior,
                file: photoInteriorFile,
                onTap: onPickInterior,
                onRemove: photoInteriorFile != null ? onRemoveInterior : null,
                height: 110,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Text(
          l10n.addVehicleLegalDocs,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),

        OnboardingDocumentTile(
          title: l10n.addVehicleDocRegBook,
          subtitle: l10n.addVehicleDocRegBookHint,
          file: regBookFile,
          onTap: onPickRegBook,
          onRemove: regBookFile != null ? onRemoveRegBook : null,
        ),
        const SizedBox(height: 10),
        OnboardingDocumentTile(
          title: l10n.addVehicleDocTokenTax,
          subtitle: l10n.addVehicleDocTokenTaxHint,
          file: tokenTaxFile,
          onTap: onPickTokenTax,
          onRemove: tokenTaxFile != null ? onRemoveTokenTax : null,
        ),
        const SizedBox(height: 10),
        OnboardingDocumentTile(
          title: l10n.addVehicleDocInsurance,
          subtitle: l10n.addVehicleDocInsuranceHint,
          file: insuranceFile,
          onTap: onPickInsurance,
          onRemove: insuranceFile != null ? onRemoveInsurance : null,
        ),
      ],
    );
  }
}
