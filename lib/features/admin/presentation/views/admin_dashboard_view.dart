import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/admin_desktop_header.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/admin_sidebar_nav.dart';
import 'admin_shop_accreditation_view.dart';
import 'admin_blacklist_tribunal_view.dart';
import 'admin_subscriptions_view.dart';
import 'admin_settings_view.dart';

class AdminDashboardView extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminDashboardView({super.key, this.onBack});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  String _activeRoute = 'dashboard';

  void _handleNavigation(String route) {
    if (route == _activeRoute) return;
    Widget destination;
    switch (route) {
      case 'accreditation':
        destination = const AdminShopAccreditationView();
        break;
      case 'blacklist':
        destination = const AdminBlacklistTribunalView();
        break;
      case 'subscriptions':
        destination = const AdminSubscriptionsView();
        break;
      case 'settings':
        destination = const AdminSettingsView();
        break;
      default:
        destination = const AdminDashboardView();
        break;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AdminSidebarNav(
            activeRoute: _activeRoute,
            onNavigate: _handleNavigation,
          ),
          Expanded(
            child: Column(
              children: [
                const AdminDesktopHeader(
                  title: 'Executive Telemetry & Platform Overview',
                  subtitle: 'National Commercial Vehicle Network • Super Admin Console',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Expanded(
                              child: AdminKpiCard(
                                title: 'Active Rentals On Road',
                                value: '412',
                                changeLabel: '+14% vs yesterday',
                                icon: Icons.directions_car_rounded,
                                accentColor: AppColors.sunsetOrange,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: AdminKpiCard(
                                title: 'Accredited Showrooms',
                                value: '87',
                                changeLabel: 'Across 12 major cities',
                                icon: Icons.store_rounded,
                                accentColor: AppColors.emeraldGreen,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: AdminKpiCard(
                                title: 'National Blacklist Flags',
                                value: '29',
                                changeLabel: '4 cases in tribunal review',
                                icon: Icons.gavel_rounded,
                                accentColor: Colors.red,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: AdminKpiCard(
                                title: '30-Day Platform Volume',
                                value: 'Rs. 4.82M',
                                changeLabel: '+22.8% MoM growth',
                                icon: Icons.account_balance_rounded,
                                accentColor: AppColors.royalNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Live Nationwide Audit Stream', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
                        const SizedBox(height: 12),
                        _auditLogItem('Al-Falah Rent a Car Lahore certified Handover #RH-8921 (Civic RS Turbo)', '2 mins ago', Icons.key_rounded, AppColors.emeraldGreen),
                        _auditLogItem('Metro Rent a Car flagged CNIC 35201-9999999-1 for dispute review', '14 mins ago', Icons.warning_rounded, Colors.red),
                        _auditLogItem('KPK Rent a Car Peshawar submitted shop accreditation documents', '45 mins ago', Icons.assignment_rounded, AppColors.royalNavy),
                        _auditLogItem('Islamabad Wheels upgraded to Pro Showroom plan (TRX-44211)', '2 hours ago', Icons.verified_rounded, AppColors.sunsetOrange),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditLogItem(String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: color.withAlpha(25), child: Icon(icon, color: color, size: 15)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.midnightNavy))),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
