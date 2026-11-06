import 'package:flutter/material.dart';

/// The suspend / unsuspend dialog for a shop: asks for the reason
/// (stored on the shop doc and in the audit log) and returns it, or
/// null when the admin cancels.
Future<String?> showSuspendDialog(
  BuildContext context, {
  required bool suspend,
}) async {
  final reasonController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(suspend ? 'Suspend this shop?' : 'Lift the suspension?'),
      content: TextField(
        controller: reasonController,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'Reason (shown in the audit log)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  if (confirmed != true) return null;
  return reasonController.text.trim();
}
