/// What on-device OCR read off a Pakistani driving license. Every
/// field is best-effort — OCR misreads happen, so the owner always
/// reviews and corrects the values before they are saved. The number
/// and expiry are filled into the same text fields the form already
/// has; nothing here is trusted blindly.
class LicenseScanResult {
  final String? licenseNumber;
  final String? dateOfExpiry;

  const LicenseScanResult({this.licenseNumber, this.dateOfExpiry});

  bool get hasAnything => licenseNumber != null || dateOfExpiry != null;

  LicenseScanResult copyWith({String? licenseNumber, String? dateOfExpiry}) {
    return LicenseScanResult(
      licenseNumber: licenseNumber ?? this.licenseNumber,
      dateOfExpiry: dateOfExpiry ?? this.dateOfExpiry,
    );
  }
}

/// Pure-Dart parsing of the text ML Kit reads off a driving license
/// (front and back). No camera or plugin is involved here, so this is
/// fully unit-testable.
class LicenseTextParser {
  static final RegExp _datePattern =
      RegExp(r'(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})');
  static final RegExp _isoDatePattern =
      RegExp(r'(\d{4})[.\-/](\d{1,2})[.\-/](\d{1,2})');
  // e.g. LHR-1234567, RWP-15-123456, ICT-12345.
  static final RegExp _licensePattern =
      RegExp(r'\b([A-Z]{2,4})[-\s]?(\d{2,3})[-\s]?(\d{4,7})\b');

  static String _digitsOnly(String input) {
    return input
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1');
  }

  static String? _normaliseDate(String raw) {
    final iso = _isoDatePattern.firstMatch(_digitsOnly(raw));
    if (iso != null) {
      final year = int.tryParse(iso.group(1)!);
      final month = int.tryParse(iso.group(2)!);
      final day = int.tryParse(iso.group(3)!);
      if (year == null || month == null || day == null) return null;
      if (day < 1 || day > 31 || month < 1 || month > 12) return null;
      return '${day.toString().padLeft(2, '0')}.'
          '${month.toString().padLeft(2, '0')}.$year';
    }
    final m = _datePattern.firstMatch(_digitsOnly(raw));
    if (m == null) return null;
    final day = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    final year = int.tryParse(m.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (day < 1 || day > 31 || month < 1 || month > 12) return null;
    return '${day.toString().padLeft(2, '0')}.'
        '${month.toString().padLeft(2, '0')}.$year';
  }

  static const _labels = [
    'license no',
    'licence no',
    'license number',
    'licence number',
    'dl no',
    'dl number',
    'driving licence no',
    'date of expiry',
    'expiry',
    'valid up to',
    'valid upto',
    'valid till',
  ];

  /// The value under a label line: the first non-empty line after a
  /// line that contains the label (case-insensitive), or the remainder
  /// on the same line when it is not itself a label.
  static String? _valueAfter(List<String> lines, String label) {
    for (int i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (!lower.contains(label)) continue;
      final after = lines[i]
          .substring(lines[i].toLowerCase().indexOf(label) + label.length)
          .trim()
          .replaceAll(RegExp(r'^[:\-–\s]+'), '');
      if (after.isNotEmpty &&
          after.length > 1 &&
          !_labels.contains(after.toLowerCase())) {
        return after;
      }
      for (int j = i + 1; j < lines.length; j++) {
        final next = lines[j].trim();
        if (next.isNotEmpty) return next;
      }
    }
    return null;
  }

  static List<String> _lines(String text) {
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  static String? _licenseNumber(String rawText) {
    final lines = _lines(rawText);
    for (final label in [
      'license no',
      'licence no',
      'license number',
      'licence number',
      'dl no',
      'dl number',
      'driving licence no',
    ]) {
      final value = _valueAfter(lines, label);
      if (value != null && value.isNotEmpty) {
        // The value may carry trailing words; keep the first token
        // that looks like a license number.
        final token = value.split(RegExp(r'\s+')).firstWhere(
              (t) => RegExp(r'[A-Za-z]').hasMatch(t) &&
                  RegExp(r'\d').hasMatch(t),
              orElse: () => value,
            );
        return token.trim();
      }
    }
    // No label OCR'd: a token shaped like a license number
    // (letters + digits, e.g. LHR-1234567). Never a bare date or a
    // 13-digit CNIC-shaped number.
    final upper = rawText.toUpperCase();
    final m = _licensePattern.firstMatch(upper);
    if (m != null) return m.group(0);
    return null;
  }

  static LicenseScanResult parseLicenseText(String rawText) {
    final lines = _lines(rawText);
    final expiry = _valueAfter(lines, 'expiry') ??
        _valueAfter(lines, 'valid up to') ??
        _valueAfter(lines, 'valid upto') ??
        _valueAfter(lines, 'valid till');
    final expiryDate =
        expiry != null ? _normaliseDate(expiry) : null;
    // Fall back to the last date in the text when no expiry label
    // OCR'd — on a license the expiry is normally the latest date.
    final dates = _datePattern
        .allMatches(_digitsOnly(rawText))
        .map((m) => _normaliseDate(m.group(0)!))
        .whereType<String>()
        .toList();
    return LicenseScanResult(
      licenseNumber: _licenseNumber(rawText),
      dateOfExpiry: expiryDate ?? (dates.isNotEmpty ? dates.last : null),
    );
  }
}
