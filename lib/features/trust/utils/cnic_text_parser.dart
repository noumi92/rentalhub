/// Phase B (C2): what CNIC OCR reads off a card. Every field is
/// best-effort — OCR misreads happen, so the owner always reviews
/// and corrects the values before they are saved.
class CnicScanResult {
  final String? name;
  final String? fatherName;
  final String? cnicNumber;
  final String? dateOfBirth;
  final String? dateOfIssue;
  final String? dateOfExpiry;
  final String? address;

  const CnicScanResult({
    this.name,
    this.fatherName,
    this.cnicNumber,
    this.dateOfBirth,
    this.dateOfIssue,
    this.dateOfExpiry,
    this.address,
  });

  bool get hasAnything =>
      name != null ||
      fatherName != null ||
      cnicNumber != null ||
      dateOfBirth != null ||
      dateOfExpiry != null ||
      address != null;

  CnicScanResult copyWith({
    String? name,
    String? fatherName,
    String? cnicNumber,
    String? dateOfBirth,
    String? dateOfIssue,
    String? dateOfExpiry,
    String? address,
  }) {
    return CnicScanResult(
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfIssue: dateOfIssue ?? this.dateOfIssue,
      dateOfExpiry: dateOfExpiry ?? this.dateOfExpiry,
      address: address ?? this.address,
    );
  }
}

/// Pure-Dart parsing of the text ML Kit reads off a Pakistani CNIC.
/// Front side: name, father's name, identity number, dates of birth,
/// issue and expiry. Back side: the address. No camera or plugin is
/// involved here, so this is fully unit-testable.
class CnicTextParser {
  static final RegExp _cnicPattern =
      RegExp(r'(\d{5})[\s\-]?(\d{7})[\s\-]?(\d{1})');
  static final RegExp _datePattern =
      RegExp(r'(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})');

  /// OCR often reads 0 as O and 1 as I/l inside numbers; normalise
  /// digit-like characters before matching numbers and dates.
  static String _digitsOnly(String input) {
    return input
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1');
  }

  static String? _normaliseDate(String raw) {
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

  static String? _cnicNumber(String text) {
    final m = _cnicPattern.firstMatch(_digitsOnly(text));
    if (m == null) return null;
    return '${m.group(1)}-${m.group(2)}-${m.group(3)}';
  }

  static const _labels = [
    'name',
    'father name',
    'identity number',
    'date of birth',
    'date of issue',
    'date of expiry',
    'address',
    'permanent address',
    'current address',
  ];

  /// The value under a label line: the first non-empty line after a
  /// line that contains the label (case-insensitive). A remainder on
  /// the same line counts only if it is not itself a label — 'Father
  /// Name' must not yield 'Name' as the father's name.
  static String? _valueAfter(List<String> lines, String label) {
    for (int i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (!lower.contains(label)) continue;
      // The value may sit on the same line after the label.
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

  static CnicScanResult parseFront(String rawText) {
    final lines = _lines(rawText);
    final dates = _datePattern
        .allMatches(_digitsOnly(rawText))
        .map((m) => _normaliseDate(m.group(0)!))
        .whereType<String>()
        .toList();

    // 'Father Name' contains 'Name', so check it first.
    final fatherName = _valueAfter(lines, 'father');
    var name = _valueAfter(lines, 'name');
    if (name != null && fatherName != null && name == fatherName) {
      name = null;
    }
    final dob = _valueAfter(lines, 'birth') != null
        ? _normaliseDate(_valueAfter(lines, 'birth')!)
        : null;
    final issue = _valueAfter(lines, 'issue') != null
        ? _normaliseDate(_valueAfter(lines, 'issue')!)
        : null;
    final expiry = _valueAfter(lines, 'expiry') != null
        ? _normaliseDate(_valueAfter(lines, 'expiry')!)
        : null;

    return CnicScanResult(
      name: name,
      fatherName: fatherName,
      cnicNumber: _cnicNumber(rawText),
      // Fall back to the dates in reading order when the labels
      // did not OCR: birth, issue, expiry.
      dateOfBirth: dob ?? (dates.isNotEmpty ? dates[0] : null),
      dateOfIssue: issue ?? (dates.length > 1 ? dates[1] : null),
      dateOfExpiry: expiry ?? (dates.length > 2 ? dates[2] : null),
    );
  }

  static CnicScanResult parseBack(String rawText) {
    final lines = _lines(rawText);
    final address = _valueAfter(lines, 'address') ??
        _valueAfter(lines, 'permanent');
    return CnicScanResult(address: address);
  }
}
