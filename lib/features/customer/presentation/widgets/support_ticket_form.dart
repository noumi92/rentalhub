import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';

/// G1: the support ticket form. A message writes to the `support_tickets`
/// collection (status 'open'). The admin tickets inbox (Gaari A16) does
/// not exist yet, so tickets are write-only — the UI says plainly that
/// the team will reach the customer on WhatsApp, rather than faking a
/// reply thread in the app.
class SupportTicketForm extends StatefulWidget {
  const SupportTicketForm({super.key});

  @override
  State<SupportTicketForm> createState() => _SupportTicketFormState();
}

class _SupportTicketFormState extends State<SupportTicketForm> {
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      AppFeedback.showError(context, 'Please write your message first.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      String customerId = 'cust-101';
      try {
        customerId =
            FirebaseAuth.instance.currentUser?.uid ?? customerId;
      } catch (_) {}
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'customerId': customerId,
        'message': message,
        'status': 'open',
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
        AppFeedback.showError(context, 'Could not send your message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message Support',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.midnightNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tell us what went wrong. Our team will reach you on WhatsApp — replies do not appear in the app yet.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'E.g. The showroom charged me extra for fuel...',
              hintStyle: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          DebouncedButton(
            text: _isSubmitting ? 'Sending...' : 'Send Message',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          if (_sent) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.emeraldGreen),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Message sent. Our team will contact you on WhatsApp.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emeraldGreen,
                    ),
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
