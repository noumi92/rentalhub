import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';

/// RQ-F9 (O17 p.7): the manual "Send WhatsApp confirmation" action
/// for the manual-booking confirm step. Extracted from
/// `OwnerManualBookingConfirmView` so the view stays under the
/// 250-line cap (rulebook §2.2).
///
/// Opens the owner's WhatsApp with the confirmation pre-written
/// (same wa.me pattern as `OwnerBookingConfirmedView`); nothing is
/// sent automatically — the owner taps send, and WhatsApp sending
/// stays gated on D2. Best-effort: a failed launch only shows an
/// error — the booking is already created by the time this runs.
Future<void> sendManualBookingWhatsappConfirmation(
  BuildContext context, {
  required String customerName,
  required String customerPhone,
  required String vehicleName,
  required DateTime pickupTime,
  required int total,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final number = _waNumber(customerPhone);
  if (number.isEmpty) {
    if (context.mounted) {
      AppFeedback.showError(context, l10n.financeDuesNoPhoneError);
    }
    return;
  }
  final when = DateFormat('d MMM yyyy, h:mm a').format(pickupTime);
  final message = l10n.bookingConfirmedWhatsappMessage(
    customerName,
    vehicleName,
    when,
    formatRs(total),
  );
  final uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(message)}');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    AppFeedback.showError(context, l10n.bookingConfirmedWhatsappFailed);
  }
}

String _waNumber(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('92')) return digits;
  if (digits.startsWith('0')) return '92${digits.substring(1)}';
  return digits;
}

/// O24: share the walk-in receipt on WhatsApp (wa.me, same pattern
/// as the booking confirmation above). Opens the owner's WhatsApp
/// with the receipt pre-written; nothing is sent automatically.
Future<void> sendManualBookingReceipt(
  BuildContext context, {
  required String bookingId,
  required String customerName,
  required String customerPhone,
  required String vehicleName,
  required DateTime pickupTime,
  required int total,
  required int remainingDues,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final number = _waNumber(customerPhone);
  if (number.isEmpty) {
    if (context.mounted) {
      AppFeedback.showError(context, l10n.financeDuesNoPhoneError);
    }
    return;
  }
  final when = DateFormat('d MMM yyyy, h:mm a').format(pickupTime);
  final message = l10n.manualBookingReceiptMessage(
    customerName,
    bookingId,
    vehicleName,
    when,
    formatRs(total),
    formatRs(remainingDues),
  );
  final uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(message)}');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    AppFeedback.showError(context, l10n.bookingConfirmedWhatsappFailed);
  }
}
