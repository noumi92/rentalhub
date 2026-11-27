import 'package:flutter/material.dart';

/// Phase 4 (4.4a) — the sticky action bar for admin detail screens:
/// a bottom strip (SafeArea, top divider, 12dp horizontal / 12dp
/// vertical padding) that stays visible while the detail scrolls,
/// so the primary actions are always in thumb reach on phones.
/// [AdminShell] renders it as the Scaffold's bottom bar on compact
/// screens (replacing the bottom nav there — the back button and
/// drawer still navigate) and as a bottom strip under the content
/// on desktop.
class AdminStickyActionBar extends StatelessWidget {
  const AdminStickyActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: child,
      ),
    );
  }
}
