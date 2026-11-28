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
/// Owner Customers KYC document slots — strictly CNIC & Driving License
/// (4 slots total: CNIC Front, CNIC Back, Driving License Front,
/// Driving License Back).
const int kycTotalSlots = 4;

bool _has(String? url) => url != null && url.isNotEmpty;

/// Ordered (field, label, url) triples for the 4 tracked KYC slots.
List<({String field, String label, String? url})> kycDocSlots(
  AppLocalizations l10n,
  CustomerEntity customer,
) =>
    [
      (
        field: 'cnicFrontUrl',
        label: l10n.customerDetailCnicFront,
        url: customer.cnicFrontUrl
      ),
      (
        field: 'cnicBackUrl',
        label: l10n.customerDetailCnicBack,
        url: customer.cnicBackUrl
      ),
      (
        field: 'licenseFrontUrl',
        label: l10n.customerDetailLicenseFront,
        url: customer.licenseFrontUrl
      ),
      (
        field: 'licenseBackUrl',
        label: l10n.customerDetailLicenseBack,
        url: customer.licenseBackUrl
      ),
    ];

/// KYC completeness for a saved customer record: CNIC Front + Back
/// and Driving License Front + Back.
bool isKycCompleteForEntity(CustomerEntity customer) {
  return _has(customer.cnicFrontUrl) &&
      _has(customer.cnicBackUrl) &&
      _has(customer.licenseFrontUrl) &&
      _has(customer.licenseBackUrl);
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

/// How many of the 4 tracked CNIC & Driving License slots have a file on the
/// record. An empty-string URL counts as missing, same as null.
int kycUploadedCount(CustomerEntity customer) {
  final urls = <String?>[
    customer.cnicFrontUrl,
    customer.cnicBackUrl,
    customer.licenseFrontUrl,
    customer.licenseBackUrl,
  ];
  assert(urls.length == kycTotalSlots);
  return urls.where(_has).length;
}
