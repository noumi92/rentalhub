import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';

/// Customer pass (2026-11-16): "Book a Car" is the Home's primary
/// action — an extended floating button (same orange FAB language as
/// the owner screens), extracted so [CustomerHomeView] stays under
/// the 250-line cap. Same destination as the quick-action tile it
/// replaces (the Shops tab). Unique heroTag: the shell keeps all
/// branches mounted.
class HomeBookCarFab extends StatelessWidget {
  const HomeBookCarFab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      heroTag: 'customer-home-book-car',
      backgroundColor: AppColors.orangeFill,
      foregroundColor: Colors.white,
      tooltip: l10n.quickBookCar,
      icon: const Icon(Icons.directions_car_rounded),
      label: Text(l10n.quickBookCar),
      onPressed: () => context.go(RouteNames.customerShops),
    );
  }
}
