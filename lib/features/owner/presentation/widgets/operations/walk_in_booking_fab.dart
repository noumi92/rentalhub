import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';

/// Walk-in booking entry as an extended floating button on the
/// Bookings (triage) screen (user layout, 2026-11-16): it was an
/// icon-only button in the app bar; the label is now visible. Same
/// destination (`ownerManualBooking`) and the same orange
/// extended-FAB treatment as the fleet Add Vehicle button. Unique
/// heroTag: the shell keeps all branches mounted, so FAB hero tags
/// must not collide across tabs.
class WalkInBookingFab extends StatelessWidget {
  const WalkInBookingFab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      key: const Key('bookings-action-walk-in'),
      heroTag: 'bookings-walk-in',
      onPressed: () => context.push(RouteNames.ownerManualBooking),
      tooltip: l10n.walkInBookingButton,
      backgroundColor: AppColors.orangeFill,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add_rounded, size: 20),
      label: Text(l10n.walkInBookingButton),
    );
  }
}
