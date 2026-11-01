import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AdminSidebarNav extends StatelessWidget {
  final String activeRoute;
  final ValueChanged<String> onNavigate;

  const AdminSidebarNav({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.midnightNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.sunsetOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RENTALHUB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0)),
                      Text('SUPER ADMIN 1440', style: TextStyle(color: AppColors.sunsetOrange, fontSize: 9.5, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          _navItem('dashboard', 'Executive KPIs', Icons.dashboard_rounded),
          _navItem('accreditation', 'Shop Accreditation', Icons.verified_user_rounded),
          _navItem('blacklist', 'Blacklist Tribunal', Icons.gavel_rounded),
          _navItem('subscriptions', 'Subscriptions & Gateways', Icons.monetization_on_rounded),
          _navItem('settings', 'Broadcasts & Exports', Icons.settings_rounded),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUPER ADMIN AUTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.sunsetOrange)),
                SizedBox(height: 4),
                Text('superadmin@rentalhub.pk', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String key, String label, IconData icon) {
    final isSelected = activeRoute == key;
    return InkWell(
      onTap: () => onNavigate(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sunsetOrange.withAlpha(40) : Colors.transparent,
          border: isSelected ? const Border(left: BorderSide(color: AppColors.sunsetOrange, width: 3.5)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.sunsetOrange : Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
