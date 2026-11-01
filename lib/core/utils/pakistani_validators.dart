/// Production-grade validation utilities tailored for the Pakistani automotive
/// and rental marketplace domain (NADRA CNIC, cellular networks, IBAN, and fleet rates).
class PakistaniValidators {
  PakistaniValidators._();

  /// Validates a Pakistani NADRA CNIC number.
  /// Standard format: XXXXX-XXXXXXX-X (13 digits total).
  ///
  /// Semantic checks:
  /// - Province digit (index 0): 1 (KP), 2 (FATA), 3 (Punjab), 4 (Sindh), 5 (Balochistan), 6 (Islamabad), 7 (GB/AJK).
  ///   Digits 0, 8, 9 are invalid province codes in Pakistan.
  /// - 13 total digits.
  /// - Gender parity: odd last digit = male, even last digit = female.
  static String? validateCnic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CNIC number is required';
    }

    final trimmed = value.trim();
    // Allow either with hyphens (15 chars) or raw 13 digits
    final rawDigits = trimmed.replaceAll('-', '').replaceAll(' ', '');

    if (rawDigits.length != 13) {
      return 'CNIC must be exactly 13 digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(rawDigits)) {
      return 'CNIC must contain only digits';
    }

    // Province code validation (first digit)
    final provinceDigit = int.parse(rawDigits[0]);
    if (provinceDigit < 1 || provinceDigit > 7) {
      return 'Invalid NADRA province prefix (must start with 1 to 7)';
    }

    // Hyphen structure check if hyphens were provided
    if (trimmed.contains('-')) {
      final hyphenPattern = RegExp(r'^\d{5}-\d{7}-\d{1}$');
      if (!hyphenPattern.hasMatch(trimmed)) {
        return 'Format must be XXXXX-XXXXXXX-X (e.g. 35201-1234567-1)';
      }
    }

    return null; // Valid
  }

  /// Formats raw 13 digits into standard NADRA format: XXXXX-XXXXXXX-X
  static String formatCnic(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 5) return digits;
    if (digits.length <= 12) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return '${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12, digits.length.clamp(12, 13))}';
  }

  /// Validates a Pakistani mobile or WhatsApp phone number.
  /// Accepts formats:
  /// - +92 300 1234567
  /// - +923001234567
  /// - 03001234567
  ///
  /// Network codes:
  /// - 30X (Mobilink / Jazz)
  /// - 31X (Zong)
  /// - 32X (Warid / Jazz)
  /// - 33X (Ufone)
  /// - 34X (Telenor)
  /// - 35X, 36X, 37X (SCO / Special)
  static String? validatePakistaniPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile/WhatsApp number is required';
    }

    final cleaned = value.replaceAll(' ', '').replaceAll('-', '');

    // Check with +92 prefix (e.g. +923001234567 -> 13 chars)
    if (cleaned.startsWith('+92')) {
      if (cleaned.length != 13) {
        return 'Phone with +92 prefix must be 13 characters (e.g. +92 300 1234567)';
      }
      if (!cleaned.startsWith('+923')) {
        return 'Invalid Pakistani cellular prefix (must be +92 3XX)';
      }
      if (!RegExp(r'^\+92[3][0-9]{9}$').hasMatch(cleaned)) {
        return 'Invalid Pakistani mobile number format';
      }
      return null;
    }

    // Check with 03 prefix (e.g. 03001234567 -> 11 chars)
    if (cleaned.startsWith('03')) {
      if (cleaned.length != 11) {
        return 'Mobile number must be 11 digits (e.g. 0300 1234567)';
      }
      if (!RegExp(r'^03[0-9]{9}$').hasMatch(cleaned)) {
        return 'Invalid Pakistani mobile number format';
      }
      return null;
    }

    // Check if user entered 9 or 10 digits without prefix
    return 'Enter a valid Pakistani mobile number starting with +92 3XX or 03XX';
  }

  /// Validates a Pakistani 24-character IBAN format.
  /// Standard structure: PK + 2 check digits + 4 bank alpha code + 16 account digits.
  /// Example: PK36MEZN0000010123456701
  static String? validatePakistaniIban(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IBAN / Account Number is required';
    }

    final cleaned = value.trim().replaceAll(' ', '').toUpperCase();

    // Standard Pakistani IBAN has length 24 and starts with PK
    if (cleaned.startsWith('PK')) {
      if (cleaned.length != 24) {
        return 'Pakistani IBAN must be exactly 24 alphanumeric characters';
      }
      if (!RegExp(r'^PK[0-9]{2}[A-Z]{4}[0-9A-Z]{16}$').hasMatch(cleaned)) {
        return 'Invalid Pakistani IBAN structure (e.g. PK36MEZN...)';
      }
      return null;
    }

    // Regular local account number (between 8 and 20 digits/characters)
    if (cleaned.length < 8 || cleaned.length > 24) {
      return 'Account number must be between 8 and 24 characters';
    }

    return null;
  }

  /// Validates vehicle rental rate inputs (must be non-negative integer).
  static String? validateRentalRate(String? value, {required String label, bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    final rate = int.tryParse(value.trim().replaceAll(',', ''));
    if (rate == null) {
      return '$label must be a valid numeric amount';
    }

    if (rate < 0) {
      return '$label cannot be negative';
    }

    if (!allowZero && rate <= 0) {
      return '$label must be greater than 0 PKR';
    }

    return null;
  }

  /// Validates vehicle seating capacity (must be integer between 1 and 50).
  static String? validateSeatingCapacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Seating capacity is required';
    }

    final capacity = int.tryParse(value.trim());
    if (capacity == null) {
      return 'Capacity must be a number';
    }

    if (capacity < 1 || capacity > 50) {
      return 'Capacity must be between 1 and 50 seats';
    }

    return null;
  }
}
