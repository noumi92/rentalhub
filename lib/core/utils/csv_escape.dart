/// RFC 4180 CSV escaping, shared by the admin exports.
///
/// The old exports either interpolated values raw (a comma in a shop
/// or city name broke the columns) or replaced commas with `;` (which
/// silently rewrote the data). A field is quoted only when it needs
/// it — it contains a comma, a quote, or a line break — and embedded
/// quotes are doubled, so the exported text round-trips unchanged.
String csvEscape(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// One CSV row from raw cell values.
String csvRow(List<String> cells) =>
    cells.map(csvEscape).join(',');
