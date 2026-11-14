import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// G1: the support ticket form. A message writes to the `support_tickets`
/// collection (status 'open'). The admin tickets inbox (Gaari A16) does
/// not exist yet, so tickets are write-only — the UI says plainly that
/// the team will reach the customer on WhatsApp, rather than faking a
/// reply thread in the app.
///
/// F-M19: when the form is opened from a shop or booking context,
/// the caller passes [shopId] / [bookingId] and the ticket is filed
/// with the link, so the admin inbox can open the shop or purchase
/// it is about. The plain support screen passes neither.
class SupportTicketForm extends StatefulWidget {
  const SupportTicketForm({super.key, this.shopId, this.bookingId});

  /// The shop this ticket is about, when filed from a shop context.
  final String? shopId;

  /// The booking this ticket is about, when filed from a trip.
  final String? bookingId;

  @override
  State<SupportTicketForm> createState() => _SupportTicketFormState();
}

class _SupportTicketFormState extends State<SupportTicketForm> {
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _sent = false;
  // Phase E (E1): the priority the admin SLA runs on — High 1 h,
  // Medium 4 h, Low 24 h. Medium is the default.
  String _priority = 'medium';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      AppFeedback.showError(context, l10n.supportWriteFirst);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      // CU-m3: a signed-out caller cannot send a ticket — the old
      // 'cust-101' fallback filed it under a shared fake identity.
      String? customerId;
      try {
        customerId = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
      if (customerId == null) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          AppFeedback.showError(context, l10n.signInRequiredGeneric);
        }
        return;
      }
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'customerId': customerId,
        'message': message,
        'status': 'open',
        'priority': _priority,
        if (widget.shopId != null) 'shopId': widget.shopId,
        if (widget.bookingId != null) 'bookingId': widget.bookingId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        setState(() {
          _sent = true;
          _isSubmitting = false;
        });
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppFeedback.showError(context, l10n.supportSendError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supportMessageTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.supportMessageHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.supportMessageLabel,
              hintStyle: Theme.of(context).textTheme.bodySmall,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            dropdownColor: Theme.of(context).colorScheme.surface,
            initialValue: _priority,
            items:  [
              DropdownMenuItem(value: 'high', child: Text(l10n.supportUrgencyHigh)),
              DropdownMenuItem(value: 'medium', child: Text(l10n.supportUrgencyMedium)),
              DropdownMenuItem(value: 'low', child: Text(l10n.supportUrgencyLow)),
            ],
            onChanged: (v) =>
                setState(() => _priority = v ?? 'medium'),
            decoration: InputDecoration(
              hintText: l10n.supportUrgencyLabel,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          DebouncedButton(
            text: _isSubmitting ? l10n.supportSending : l10n.supportSendMessage,
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          if (_sent) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.successTextFor(Theme.of(context).brightness)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.supportMessageSent,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.successTextFor(Theme.of(context).brightness)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
