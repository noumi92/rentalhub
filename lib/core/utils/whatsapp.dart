/// C3: shared WhatsApp helpers — normalizing a Pakistani number for
/// wa.me and building the chat link. Used by the booking success screen
/// and the car detail action bar so the same number handling lives in
/// one place.
String normalizeWaNumber(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) {
    digits = '92${digits.substring(1)}';
  }
  return digits;
}

/// The wa.me link for [phone] with a prefilled [message], or null when
/// the number is empty (the caller then says so honestly instead of
/// opening a broken link).
Uri? whatsappUri({required String phone, required String message}) {
  final normalized = normalizeWaNumber(phone);
  if (normalized.isEmpty) return null;
  return Uri.parse(
    'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
  );
}
