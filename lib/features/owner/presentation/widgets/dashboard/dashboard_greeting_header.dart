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
    // DateFormat('EEEE, d MMMM y') shows English month/day names to Urdu users.
    final date = DateFormat('EEEE, d MMMM y', Localizations.localeOf(context).languageCode).format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardGreeting(name),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
