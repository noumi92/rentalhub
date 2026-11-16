import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// Showroom redesign Phase 3 — the KYC document slots.
///
/// The app tracks 11 slots, verified against [CustomerEntity],
/// [KycDraft] and [KycCustomerSaver] (which maps every draft field
/// onto the entity). In order:
/// 1. Profile photo ([CustomerEntity.profilePhotoUrl] / draft facePhoto)
/// 2. Thumbprint — legacy single-thumbprint photo
///    ([CustomerEntity.thumbprintUrl]); the wizard no longer captures
///    it (step 2 takes the two 4-finger photos instead) but older
///    records still carry it, so it stays a tracked slot.
/// 3. Left 4 fingers ([CustomerEntity.leftFingerprintUrl])
/// 4. Right 4 fingers ([CustomerEntity.rightFingerprintUrl])
/// 5. CNIC front ([CustomerEntity.cnicFrontUrl])
/// 6. CNIC back ([CustomerEntity.cnicBackUrl])
/// 7. License front ([CustomerEntity.licenseFrontUrl])
/// 8. License back ([CustomerEntity.licenseBackUrl])
/// 9. Utility bill ([CustomerEntity.utilityBillUrl])
/// 10. Extra documents ([CustomerEntity.extraDocumentUrls]) — one
///     slot, uploaded iff the list is non-empty (the saver stores
///     each extra photo under `extraDocumentUrls_$i`).
/// 11. Signature ([CustomerEntity.signatureUrl] / draft signaturePng)
///
/// Note [KycDraft.isKycComplete] does NOT require the thumbprint or
/// extra documents (nor the CNIC back): it requires CNIC + name,
/// face, both finger photos, both license photos, license number,
/// utility bill, signature and terms. The grid still shows all 11
/// tracked slots — a complete record can legitimately read 9/11.
const int kycTotalSlots = 11;

bool _has(String? url) => url != null && url.isNotEmpty;

/// Ordered (label, url) pairs for the 11 tracked slots. Extra
/// documents shows the first extra file (if any); the slot counts as
/// uploaded when the list is non-empty.
List<({String label, String? url})> kycDocSlots(
  AppLocalizations l10n,
  CustomerEntity customer,
) => [
  (label: l10n.customerDetailProfilePhoto, url: customer.profilePhotoUrl),
  (label: l10n.kycWizardThumbprint, url: customer.thumbprintUrl),
  (label: l10n.kycLeftFourFingers, url: customer.leftFingerprintUrl),
  (label: l10n.kycRightFourFingers, url: customer.rightFingerprintUrl),
  (label: l10n.customerDetailCnicFront, url: customer.cnicFrontUrl),
  (label: l10n.customerDetailCnicBack, url: customer.cnicBackUrl),
  (label: l10n.customerDetailLicenseFront, url: customer.licenseFrontUrl),
  (label: l10n.customerDetailLicenseBack, url: customer.licenseBackUrl),
  (label: l10n.kycWizardUtilityBill, url: customer.utilityBillUrl),
  (
    label: l10n.kycWizardExtraDocs,
    url: customer.extraDocumentUrls.isEmpty
        ? null
        : customer.extraDocumentUrls.first,
  ),
  (label: l10n.customerDetailSignature, url: customer.signatureUrl),
];

/// How many of the 11 tracked slots have a file on the record. An
/// empty-string URL counts as missing, same as null. Computed
/// straight from the entity fields (no labels needed) so unit tests
/// can call it without a widget pump.
int kycUploadedCount(CustomerEntity customer) {
  final urls = <String?>[
    customer.profilePhotoUrl,
    customer.thumbprintUrl,
    customer.leftFingerprintUrl,
    customer.rightFingerprintUrl,
    customer.cnicFrontUrl,
    customer.cnicBackUrl,
    customer.licenseFrontUrl,
    customer.licenseBackUrl,
    customer.utilityBillUrl,
    customer.extraDocumentUrls.isEmpty
        ? null
        : customer.extraDocumentUrls.first,
    customer.signatureUrl,
  ];
  assert(urls.length == kycTotalSlots);
  return urls.where(_has).length;
}
