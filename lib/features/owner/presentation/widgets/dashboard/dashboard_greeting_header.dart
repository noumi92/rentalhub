import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';

/// Audit impl (O29): the dashboard greeting — "Assalam-o-Alaikum,
/// `<owner name>`" with today's date underneath. The name comes from
/// the real shop document (`owner_name`); the shop name is the
/// fallback when the shop has no owner name saved.
class DashboardGreetingHeader extends StatelessWidget {
  final String ownerName;
  final String shopName;

  const DashboardGreetingHeader({
    super.key,
    required this.ownerName,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = ownerName.isNotEmpty ? ownerName : shopName;
    // Audit 2026-11-15 DS-5: the locale is passed explicitly — a bare
    // DateFormat('EEE, d MMM') shows English month/day names to Urdu
    // users. Phase 1 showroom redesign: the SHORT date ("Mon, 16 Nov"
    // style) sits on the same line as the greeting, per the guide.
    final date = DateFormat('EEE, d MMM', Localizations.localeOf(context).languageCode).format(DateTime.now());
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.dashboardGreeting(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '•',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          date,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
