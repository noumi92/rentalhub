import 'package:flutter/material.dart';

import '../widgets/admin_shell.dart';

/// Phase A (A6) — an honest placeholder for an admin section whose
/// real screen arrives in a later phase. No fake data, no snackbar-only
/// actions: just what it is and when it lands. Used for Shops (Phase B)
/// and Subscriptions (Phase F, gated on Play Console) until then.
class AdminComingSoonView extends StatelessWidget {
  const AdminComingSoonView({
    super.key,
    required this.activeRoute,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String activeRoute;
  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeRoute: activeRoute,
      title: title,
      subtitle: subtitle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_rounded,
                  size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
