import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';

/// Feedback (5-tab navigation): the customer app's bottom navigation —
/// Home, My Bookings, Wallet, Support, Profile — five tabs, matching the
/// owner app's five tabs (Dashboard, Fleet, Bookings, Customers,
/// Settings). The five tab screens show it; pushed screens (settings,
/// SOS, disputes, the booking flow, …) use a back button instead.
class CustomerBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomerBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    RouteNames.customerHome,
    RouteNames.customerBookings,
    RouteNames.customerWallet,
    RouteNames.customerSupport,
    RouteNames.customerProfile,
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
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.support_agent_rounded),
          label: 'Support',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
