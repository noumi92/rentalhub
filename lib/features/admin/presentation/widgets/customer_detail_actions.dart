import 'package:flutter/material.dart';


/// The action row on the customer detail screen, extracted from
/// AdminCustomerDetailView so the view stays under the 250-line cap:
/// the admin-note composer and the Watchlist / Report-to-blacklist
/// actions.
class CustomerDetailActions extends StatelessWidget {
  const CustomerDetailActions({
    super.key,
    required this.noteController,
    required this.isWorking,
    required this.onAddNote,
    required this.onWatchlist,
    required this.onBlacklist,
  });

  final TextEditingController noteController;
  final bool isWorking;
  final VoidCallback onAddNote;
  final VoidCallback onWatchlist;
  final VoidCallback onBlacklist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Add an admin note…',
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isWorking ? null : onAddNote,
              child: const Text('Add note'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isWorking ? null : onWatchlist,
                child: const Text('Add to watchlist'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700),
                onPressed: isWorking ? null : onBlacklist,
                child: const Text('Report to blacklist'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
