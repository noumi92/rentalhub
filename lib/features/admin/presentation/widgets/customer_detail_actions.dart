import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';

/// The action row on the customer detail screen, extracted from
/// AdminCustomerDetailView so the view stays under the 250-line cap:
/// the admin-note composer and the Watchlist / Report-to-blacklist
/// actions.
///
/// Mobile-first (2026-11-10): on a phone the two actions stack
/// full-width — side by side each is ~150dp and "Report to blacklist"
/// clips at large text scales. All buttons are 48dp tall.
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
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
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
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48)),
              child: const Text('Add note'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _watchlistButton(),
              const SizedBox(height: 12),
              _blacklistButton(),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _watchlistButton()),
              const SizedBox(width: 12),
              Expanded(child: _blacklistButton()),
            ],
          ),
      ],
    );
  }

  Widget _watchlistButton() {
    return OutlinedButton(
      onPressed: isWorking ? null : onWatchlist,
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48)),
      child: const Text('Add to watchlist'),
    );
  }

  Widget _blacklistButton() {
    return FilledButton(
      style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          minimumSize: const Size(0, 48)),
      onPressed: isWorking ? null : onBlacklist,
      child: const Text('Report to blacklist'),
    );
  }
}
