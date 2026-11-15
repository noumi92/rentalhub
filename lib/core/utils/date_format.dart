import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Localized date formatting (audit 2026-11-15, DS-5).
///
/// A raw `'${d.day}/${d.month}/${d.year}'` is ambiguous (`5/11/2026` is
/// 5 Nov or 11 May) and ignores the locale; a bare `DateFormat('...')`
/// with no locale shows English month names to Urdu users. Every UI
/// date goes through here — the locale comes from
/// `Localizations.localeOf(context)`, the same source the fixed
/// neighbours (`booking_summary_card.dart`,
/// `dashboard_schedule_section.dart`, the subscription views) use.
/// - [formatDate]: date only, e.g. "5 Nov 2026" (Urdu month name in Urdu).
/// - [formatDateTime]: date + time, e.g. "5 Nov 2026 • 2:30 PM".
/// - [formatDayTime]: short day + time without the year, e.g.
///   "5 Nov, 2:30 PM", for dense rows (triage cards, vehicle-detail
///   bookings, WhatsApp log) where the year adds noise.
/// PDFs have no BuildContext: their static `_date` helpers use
/// [formatDateEn] — unambiguous, and English month names are correct
/// there because the legal document is in English.
String _locale(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// English date with no intl dependency, for PDFs and other
/// context-free code: `DateFormat.yMMMd('en')` throws
/// `LocaleDataException` in plain unit tests (no locale data is
/// initialised without a Widgets binding), so the legal documents
/// format the date by hand. Output: "5 Nov 2026".
String formatDateEn(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(_locale(context)).format(date);

String formatDateTime(BuildContext context, DateTime date) =>
    '${formatDate(context, date)} • ${DateFormat.jm(_locale(context)).format(date)}';

String formatDayTime(BuildContext context, DateTime date) =>
    DateFormat.MMMd(_locale(context)).add_jm().format(date);
