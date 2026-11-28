import 'package:flutter/material.dart';

/// Opens a Material date picker and writes the selected date into [controller]
/// formatted as `DD.MM.YYYY` (matching CNIC/license date validation).
Future<void> pickFormattedDate({
  required BuildContext context,
  required TextEditingController controller,
  bool isDob = true,
}) async {
  final now = DateTime.now();
  DateTime initial =
      isDob ? DateTime(now.year - 25, now.month, now.day) : DateTime(now.year + 5, now.month, now.day);
  final parts = controller.text.trim().split(RegExp(r'[./-]'));
  if (parts.length == 3) {
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d != null && m != null && y != null && y >= 1900 && y <= 2100) {
      initial = DateTime(y, m, d);
    }
  }
  final firstDate = isDob ? DateTime(1920) : DateTime(now.year - 5);
  final lastDate = isDob ? now : DateTime(now.year + 30);
  if (initial.isBefore(firstDate)) initial = firstDate;
  if (initial.isAfter(lastDate)) initial = lastDate;

  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (picked == null) return;
  final dd = picked.day.toString().padLeft(2, '0');
  final mm = picked.month.toString().padLeft(2, '0');
  controller.text = '$dd.$mm.${picked.year}';
}
