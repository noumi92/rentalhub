import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'onboarding_document_tile.dart';
import 'onboarding_photo_upload_box.dart';

class ShopKycDocsStepWidget extends StatelessWidget {
  final XFile? shopHeaderFile;
  final VoidCallback onPickShopHeader;
  final VoidCallback onRemoveShopHeader;

  final XFile? fleetPhoto1File;
  final VoidCallback onPickFleet1;
  final VoidCallback onRemoveFleet1;

  final XFile? fleetPhoto2File;
  final VoidCallback onPickFleet2;
  final VoidCallback onRemoveFleet2;

  final XFile? fleetPhoto3File;
  final VoidCallback onPickFleet3;
  final VoidCallback onRemoveFleet3;

  final XFile? cnicFrontFile;
  final VoidCallback onPickCnicFront;
  final VoidCallback onRemoveCnicFront;

  final XFile? cnicBackFile;
  final VoidCallback onPickCnicBack;
  final VoidCallback onRemoveCnicBack;

  final XFile? ntnFile;
  final VoidCallback onPickNtn;
  final VoidCallback onRemoveNtn;

  final XFile? selfieFile;
  final VoidCallback onPickSelfie; // Front camera only
  final VoidCallback onRemoveSelfie;

  const ShopKycDocsStepWidget({
    super.key,
    required this.shopHeaderFile,
    required this.onPickShopHeader,
    required this.onRemoveShopHeader,
    required this.fleetPhoto1File,
    required this.onPickFleet1,
    required this.onRemoveFleet1,
    required this.fleetPhoto2File,
    required this.onPickFleet2,
    required this.onRemoveFleet2,
    required this.fleetPhoto3File,
    required this.onPickFleet3,
    required this.onRemoveFleet3,
    required this.cnicFrontFile,
    required this.onPickCnicFront,
    required this.onRemoveCnicFront,
    required this.cnicBackFile,
    required this.onPickCnicBack,
    required this.onRemoveCnicBack,
    required this.ntnFile,
    required this.onPickNtn,
    required this.onRemoveNtn,
    required this.selfieFile,
    required this.onPickSelfie,
    required this.onRemoveSelfie,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1 Picture as Shop Header (Back Camera / Gallery / Remove)
        Text(
          'Shop Header Showcase Banner',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload photo from camera or gallery. Appears at the top of your public profile.',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 10),
        OnboardingPhotoUploadBox(
          label: 'Shop Header Banner Photo',
          file: shopHeaderFile,
          height: 130,
          onTap: onPickShopHeader,
          onRemove: shopHeaderFile != null ? onRemoveShopHeader : null,
        ),
        const SizedBox(height: 20),

        // 3 Fleet Photos (Back Camera / Gallery / Remove)
        Text(
          'Showroom Fleet Photos (3 Required)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload authentic photos of cars parked at your showroom.',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OnboardingPhotoUploadBox(
                label: 'Fleet Car 1',
                file: fleetPhoto1File,
                onTap: onPickFleet1,
                onRemove: fleetPhoto1File != null ? onRemoveFleet1 : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OnboardingPhotoUploadBox(
                label: 'Fleet Car 2',
                file: fleetPhoto2File,
                onTap: onPickFleet2,
                onRemove: fleetPhoto2File != null ? onRemoveFleet2 : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OnboardingPhotoUploadBox(
                label: 'Fleet Car 3',
                file: fleetPhoto3File,
                onTap: onPickFleet3,
                onRemove: fleetPhoto3File != null ? onRemoveFleet3 : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Legal & KYC Docs
        Text(
          'Owner Identity & Tax Verification',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Mandatory compliance for showroom verification.',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 10),

        OnboardingDocumentTile(
          title: 'CNIC Front Photo',
          subtitle: 'Daylight photo of owner CNIC front',
          file: cnicFrontFile,
          onTap: onPickCnicFront,
          onRemove: cnicFrontFile != null ? onRemoveCnicFront : null,
        ),
        const SizedBox(height: 10),

        OnboardingDocumentTile(
          title: 'CNIC Back Photo',
          subtitle: 'Daylight photo showing permanent address',
          file: cnicBackFile,
          onTap: onPickCnicBack,
          onRemove: cnicBackFile != null ? onRemoveCnicBack : null,
        ),
        const SizedBox(height: 10),

        OnboardingDocumentTile(
          title: 'FBR NTN Certificate / Business Registration',
          subtitle: 'Verified filer certificate or showroom deed',
          file: ntnFile,
          onTap: onPickNtn,
          onRemove: ntnFile != null ? onRemoveNtn : null,
        ),
        const SizedBox(height: 10),

        // Requirement 1: Owner Live Selfie (FRONT CAMERA ONLY + REMOVE)
        OnboardingDocumentTile(
          title: 'Owner Live Selfie Holding CNIC (Front Camera Only)',
          subtitle: 'Instant live biometric selfie capture',
          file: selfieFile,
          onTap: onPickSelfie,
          onRemove: selfieFile != null ? onRemoveSelfie : null,
        ),
      ],
    );
  }
}
