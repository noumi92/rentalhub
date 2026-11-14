/// Shared email-format validation (invite form, accept view).
/// Deliberately strict enough to catch the common mistakes (missing
/// `@`, missing domain, spaces) without rejecting valid addresses:
/// `^[^@\s]+@[^@\s]+\.[^@\s]+$`. This is a format check only — it
/// never proves the address exists or belongs to anyone.
bool isValidEmailAddress(String email) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}
