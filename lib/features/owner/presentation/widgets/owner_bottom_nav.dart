import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';

/// Feedback (5-tab navigation): the owner app's bottom navigation —
/// Dashboard, Fleet, Bookings, Customers, Settings — five tabs, matching
/// the customer app's five tabs (Home, Bookings, Wallet, Support,
/// Profile) and the vendor 5-section map. The five tab screens show it;
/// pushed screens (add vehicle, handover, finance, …) use a back button
/// instead. Settings is the "More" hub: it links to finance, subscription,
/// WhatsApp logs, notifications, blacklist and fixed routes.
class OwnerBottomNav extends StatelessWidget {
  final int currentIndex;

  const OwnerBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    RouteNames.ownerDashboard,
    RouteNames.ownerFleet,
    RouteNames.ownerRequests,
    RouteNames.ownerCustomers,
    RouteNames.ownerSettings,
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car_rounded),
          label: 'Fleet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Customers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
