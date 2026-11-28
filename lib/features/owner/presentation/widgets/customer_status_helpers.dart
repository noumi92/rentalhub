import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/utils/customer_grouping.dart';

/// Walk-in customer CRM — the derived / per-shop statuses the
/// customers list and the booking pick share. All pure functions
/// over data the caller already loaded; no new fetch anywhere.
///
/// * Stored per-shop status: [shopStatusFor] reads the record's
///   `shopStatuses` map (see [CustomerEntity.statusForShop]).
/// * KYC Incomplete: [isCustomerKycComplete] reuses the
///   `KycDraft.isKycComplete` slot logic, mapped onto the entity
///   fields (the draft's CNIC + name + terms have no entity
///   counterpart — a saved record always carries a name/CNIC).
/// * Dormant: [isCustomerDormant], 90 days since the last booking.

/// Days without a booking after which a customer reads as Dormant
/// (user decision 2026-11-21).
const int dormantAfterDays = 90;

/// This shop's stored status for a record, defaulting to 'active'
/// when the record is null or carries no entry for the shop.
///
/// Shop ids have two forms (rulebook D12): the bare owner UID the
/// owner app passes around, and the `shop_<uid>` document id the
/// `shopStatuses` map is keyed by. Both denote the same shop, so
/// the document-id form is tried as a fallback when the id as
/// given has no entry — the same dual-form read the datasources
/// already do with `candidateShopIds`.
String shopStatusFor(CustomerEntity? record, String shopId) {
  if (record == null) return CustomerEntity.statusActive;
  final direct = record.statusForShop(shopId);
  if (direct != CustomerEntity.statusActive ||
      shopId.startsWith('shop_')) {
    return direct;
  }
  return record.statusForShop('shop_$shopId');
}

bool _has(String? url) => url != null && url.isNotEmpty;

/// KYC complete on a saved record: either CNIC front & back documents are
/// uploaded (walk-in KYC), or all legacy full-KYC slots are present.
bool isCustomerKycComplete(CustomerEntity record) {
  if (_has(record.cnicFrontUrl) && _has(record.cnicBackUrl)) return true;
  return _has(record.profilePhotoUrl) &&
      _has(record.leftFingerprintUrl) &&
      _has(record.rightFingerprintUrl) &&
      _has(record.licenseFrontUrl) &&
      _has(record.licenseBackUrl) &&
      (record.licenseNumber?.trim().isNotEmpty ?? false) &&
      _has(record.utilityBillUrl) &&
      _has(record.signatureUrl);
}

/// Dormant: the customer has booked before, but the last booking
/// is at least [dormantAfterDays] old. A customer who never booked
/// (`lastBookingAt` null) is New, not Dormant.
bool isCustomerDormant(DateTime? lastBookingAt, {DateTime? now}) {
  if (lastBookingAt == null) return false;
  return (now ?? DateTime.now()).difference(lastBookingAt).inDays >=
      dormantAfterDays;
}

/// Row-level derived badges for a customers-list row. KYC
/// Incomplete is only derivable when a saved record exists —
/// booking-derived rows (no record) carry no KYC data, so they
/// are never labelled incomplete.
({bool blocked, bool kycIncomplete, bool dormant}) rowStatusBadges(
  CustomerSummary summary,
  String shopId, {
  DateTime? now,
}) {
  final record = summary.savedRecord;
  return (
    blocked: shopStatusFor(record, shopId) ==
        CustomerEntity.statusBlocked,
    kycIncomplete: record != null && !isCustomerKycComplete(record),
    dormant: isCustomerDormant(summary.lastBookingAt, now: now),
  );
}
