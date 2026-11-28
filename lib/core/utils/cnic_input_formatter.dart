import 'package:flutter/services.dart';

/// Automatically formats Pakistani CNIC input as `XXXXX-XXXXXXX-X` (13 digits,
/// 15 characters total) while typing or pasting, inserting hyphens after the
/// 5th and 12th digits and keeping the cursor positioned naturally.
class CnicInputFormatter extends TextInputFormatter {
  const CnicInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clamped = digits.length > 13 ? digits.substring(0, 13) : digits;

    final buf = StringBuffer();
    for (var i = 0; i < clamped.length; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(clamped[i]);
    }
    final formatted = buf.toString();

    // Compute cursor offset based on how many digits preceded the cursor.
    final selEnd = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = newValue.text
        .substring(0, selEnd)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, clamped.length);
    var offset = digitsBeforeCursor;
    if (digitsBeforeCursor > 5) offset++;
    if (digitsBeforeCursor > 12) offset++;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset.clamp(0, formatted.length)),
    );
  }
}
