import 'package:intl/intl.dart';

/// Money formatting (audit C5, foundation 2026-11-08).
///
/// One helper for every rupee amount in the app: `formatRs(4820000)` is
/// `"4,820,000"`. Call sites render it ONLY through a localised money key
/// — `l10n.amountRs(formatRs(x))` (which yields "Rs. 4,820,000" in English
/// and the Urdu amountRs form in Urdu) or another money key whose placeholder is
/// typed String in the `.arb` files (rulebook §4.5: money placeholders are
/// String). Never interpolate a raw int, and never write the inline
/// `'Rs. ${formatRs(x)}'` form — it hardcodes the English word order and
/// renders the Urdu composite strings with the amount in the wrong place.
///
/// The pattern is locale-pinned to `'en'` on purpose: the app's amounts
/// are shown with Western digits and comma grouping in both English and
/// Urdu (the Urdu `.arb` strings already interpolate raw Western digits),
/// and pinning keeps the grouping identical whatever the device locale is
/// — a bare `NumberFormat('#,##0')` would follow the device locale.
/// Fractions are dropped: rupee amounts in this app are whole rupees.
String formatRs(num amount) => NumberFormat('#,##0', 'en').format(amount);
