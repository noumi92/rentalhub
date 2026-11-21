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

/// Ordered (field, label, url) triples for the 11 tracked slots.
/// [field] is the [CustomerEntity] field name (used by KYC replace
/// to write back exactly one slot). Extra documents shows the first
/// extra file (if any); the slot counts as uploaded when the list
/// is non-empty.
List<({String field, String label, String? url})> kycDocSlots(
  AppLocalizations l10n,
  CustomerEntity customer,
) => [
  (field: 'profilePhotoUrl', label: l10n.customerDetailProfilePhoto, url: customer.profilePhotoUrl),
  (field: 'thumbprintUrl', label: l10n.kycWizardThumbprint, url: customer.thumbprintUrl),
  (field: 'leftFingerprintUrl', label: l10n.kycLeftFourFingers, url: customer.leftFingerprintUrl),
  (field: 'rightFingerprintUrl', label: l10n.kycRightFourFingers, url: customer.rightFingerprintUrl),
  (field: 'cnicFrontUrl', label: l10n.customerDetailCnicFront, url: customer.cnicFrontUrl),
  (field: 'cnicBackUrl', label: l10n.customerDetailCnicBack, url: customer.cnicBackUrl),
  (field: 'licenseFrontUrl', label: l10n.customerDetailLicenseFront, url: customer.licenseFrontUrl),
  (field: 'licenseBackUrl', label: l10n.customerDetailLicenseBack, url: customer.licenseBackUrl),
  (field: 'utilityBillUrl', label: l10n.kycWizardUtilityBill, url: customer.utilityBillUrl),
  (
    field: 'extraDocumentUrls',
    label: l10n.kycWizardExtraDocs,
    url: customer.extraDocumentUrls.isEmpty
        ? null
        : customer.extraDocumentUrls.first,
  ),
  (field: 'signatureUrl', label: l10n.customerDetailSignature, url: customer.signatureUrl),
];

/// Walk-in CRM: the derived KYC-completeness check for a SAVED
/// record (the detail-screen "KYC Incomplete" chip). Same slot
/// list as [KycDraft.isKycComplete] — face + both finger photos +
/// both license photos + license number + utility bill + signature
/// — but read off the stored URLs, so no draft, CNIC/name or terms
/// check is involved (those are wizard concerns, not record state).
bool isKycCompleteForEntity(CustomerEntity customer) {
  return _has(customer.profilePhotoUrl) &&
      _has(customer.leftFingerprintUrl) &&
      _has(customer.rightFingerprintUrl) &&
      _has(customer.licenseFrontUrl) &&
      _has(customer.licenseBackUrl) &&
      (customer.licenseNumber ?? '').trim().isNotEmpty &&
      _has(customer.utilityBillUrl) &&
      _has(customer.signatureUrl);
}

/// Walk-in CRM (KYC replace): the customer with exactly one slot
/// URL replaced. The CNIC number is never touched here — a replaced
/// CNIC photo must not change the record key. Replacing
/// 'extraDocumentUrls' APPENDS the new file to the list (the slot
/// shows the first file; a replace that overwrote the list would
/// silently drop the owner's earlier extra documents).
CustomerEntity customerWithSlotUrl(
  CustomerEntity customer,
  String field,
  String url,
) {
  switch (field) {
    case 'profilePhotoUrl':
      return customer.copyWith(profilePhotoUrl: url);
    case 'thumbprintUrl':
      return customer.copyWith(thumbprintUrl: url);
    case 'leftFingerprintUrl':
      return customer.copyWith(leftFingerprintUrl: url);
    case 'rightFingerprintUrl':
      return customer.copyWith(rightFingerprintUrl: url);
    case 'cnicFrontUrl':
      return customer.copyWith(cnicFrontUrl: url);
    case 'cnicBackUrl':
      return customer.copyWith(cnicBackUrl: url);
    case 'licenseFrontUrl':
      return customer.copyWith(licenseFrontUrl: url);
    case 'licenseBackUrl':
      return customer.copyWith(licenseBackUrl: url);
    case 'utilityBillUrl':
      return customer.copyWith(utilityBillUrl: url);
    case 'extraDocumentUrls':
      return customer.copyWith(
        extraDocumentUrls: [...customer.extraDocumentUrls, url],
      );
    case 'signatureUrl':
      return customer.copyWith(signatureUrl: url);
    default:
      throw ArgumentError.value(field, 'field', 'not a KYC slot field');
  }
}

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
